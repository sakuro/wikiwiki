# frozen_string_literal: true

require "json"
require "jwt"
require "net/http"
require "uri"

module Wikiwiki
  # Handles HTTP communication with the Wikiwiki REST API
  #
  # @example
  #   auth = Wikiwiki::Auth.password(password: "secret")
  #   api = Wikiwiki::API.new(wiki_id: "my-wiki", auth:)
  #   pages = api.get_pages
  class API
    attr_reader :logger
    attr_reader :token

    BASE_URL = URI.parse("https://api.wikiwiki.jp").freeze
    private_constant :BASE_URL

    # Initialize a new API client and authenticate
    #
    # @param wiki_id [String] the wiki identifier
    # @param auth [Auth::Password, Auth::ApiKey] authentication credentials
    # @param logger [Logger] logger instance for request/response logging
    # @param rate_limiter [RateLimiter] rate limiter instance (default: RateLimiter.default)
    # @raise [Error] if authentication fails
    def initialize(wiki_id:, auth:, logger:, rate_limiter: RateLimiter.default)
      @wiki_id = wiki_id
      @rate_limiter = rate_limiter
      @logger = logger
      @token = authenticate(auth)
    end

    # Get list of all pages
    #
    # @return [Hash] response with "pages" key containing array of page info
    # @raise [Error] if request fails
    def get_pages
      uri = BASE_URL + "/#{wiki_id}/pages"
      response = request(:get, uri)

      parse_json_response(response)
    end

    # Get a specific page
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @return [Hash] response with "page", "source", and "timestamp" keys
    # @raise [Error] if request fails
    def get_page(encoded_page_name:)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}"
      response = request(:get, uri)

      parse_json_response(response)
    end

    # Update a page
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @param source [String] the page source content
    # @return [void]
    # @raise [Error] if request fails
    def put_page(encoded_page_name:, source:)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}"
      response = request(:put, uri, body: {"source" => source})

      parse_json_response(response)
    end

    # Get list of attachments on a page
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @return [Hash] response with "attachments" key containing hash of file info
    # @raise [Error] if request fails
    def get_attachments(encoded_page_name:)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}/attachments"
      response = request(:get, uri)

      parse_json_response(response)
    end

    # Get a specific attachment
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @param encoded_attachment_name [String] the URL-encoded attachment file name
    # @param rev [String, nil] optional MD5 hash for specific revision
    # @return [Hash] file info with Base64-encoded "src" data
    # @raise [Error] if request fails
    def get_attachment(encoded_page_name:, encoded_attachment_name:, rev: nil)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}/attachment/#{encoded_attachment_name}"
      uri.query = "rev=#{rev}" if rev
      response = request(:get, uri)

      parse_json_response(response)
    end

    # Upload an attachment to a page
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @param attachment_name [String] the attachment file name (not URL-encoded; sent in JSON body)
    # @param encoded_content [String] Base64-encoded file data
    # @return [void]
    # @raise [Error] if request fails
    def put_attachment(encoded_page_name:, attachment_name:, encoded_content:)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}/attachment"
      response = request(:put, uri, body: {"filename" => attachment_name, "data" => encoded_content})

      parse_json_response(response)
    end

    # Delete an attachment from a page
    #
    # @param encoded_page_name [String] the URL-encoded page name
    # @param encoded_attachment_name [String] the URL-encoded attachment file name
    # @return [void]
    # @raise [Error] if request fails
    def delete_attachment(encoded_page_name:, encoded_attachment_name:)
      uri = BASE_URL + "/#{wiki_id}/page/#{encoded_page_name}/attachment/#{encoded_attachment_name}"
      response = request(:delete, uri)

      parse_json_response(response)
    end

    # Authenticate with the Wikiwiki API
    #
    # @param auth [Auth::Password, Auth::ApiKey, Auth::Token] authentication credentials
    # @return [String] JWT token
    # @raise [Error] if authentication fails
    private def authenticate(auth)
      token = if auth.is_a?(Auth::Token)
                auth.token
              else
                uri = BASE_URL + "/#{wiki_id}/auth"
                response = request(:post, uri, body: auth.to_h, authenticate: false)
                data = parse_json_response(response)
                data["token"]
              end

      validate_token_expiry(token) if auth.is_a?(Auth::Token)
      token
    end

    # Validate JWT token expiry
    #
    # @param token [String] JWT token
    # @return [void]
    # @raise [AuthenticationError] if token has expired
    private def validate_token_expiry(token)
      payload, = JWT.decode(token, nil, false)
      exp = payload["exp"]

      if exp
        exp_time = Time.at(exp)
        if Time.now >= exp_time
          raise AuthenticationError, "Token has expired at #{exp_time.iso8601}"
        end

        logger.debug("[#{wiki_id}] Token expires at: #{exp_time.iso8601}")
      else
        logger.debug("[#{wiki_id}] Token has no expiration")
      end
    rescue JWT::DecodeError => e
      logger.debug("[#{wiki_id}] Failed to decode token: #{e.message}")
    end

    # Parse JSON response
    #
    # @param response [Net::HTTPResponse] HTTP response
    # @return [Hash] parsed response body
    # @raise [AuthenticationError] if authentication fails (401)
    # @raise [ResourceNotFoundError] if resource not found (404)
    # @raise [ServerError] if server error (5xx)
    # @raise [APIError] if other API request fails
    private def parse_json_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        message = "API request failed: #{response.code} #{response.message}"
        case Integer(response.code, 10)
        when 401
          raise AuthenticationError, message
        when 404
          raise ResourceNotFoundError, message
        when 500..599
          raise ServerError, message
        else
          raise APIError, message
        end
      end

      JSON.parse(response.body)
    end

    # Send HTTP request
    #
    # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
    # @param uri [URI::HTTPS] request URI
    # @param body [Hash, nil] request body (only for methods that permit body)
    # @param authenticate [Boolean] whether to include authentication header
    # @return [Net::HTTPResponse] HTTP response
    private def request(method, uri, body: nil, authenticate: true)
      @rate_limiter.acquire!

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request_class = Net::HTTP.const_get(method.capitalize)
      request = request_class.new(uri.request_uri)

      if request.request_body_permitted? && body
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end

      request["Authorization"] = "Bearer #{token}" if authenticate

      log_request(method, uri, request)
      response = http.request(request)
      log_response(response)

      response
    end

    # Log HTTP request details
    #
    # @param method [Symbol] HTTP method
    # @param uri [URI::HTTPS] request URI
    # @param request [Net::HTTPRequest] HTTP request object
    private def log_request(method, uri, request)
      logger.info("[#{wiki_id}] API Request: #{method.upcase} #{uri}")

      request.each_header do |key, value|
        if key.casecmp("authorization").zero?
          logger.debug("[#{wiki_id}]   #{key}: Bearer ***")
        else
          logger.debug("[#{wiki_id}]   #{key}: #{value}")
        end
      end
    end

    # Log HTTP response details
    #
    # @param response [Net::HTTPResponse] HTTP response object
    private def log_response(response)
      logger.info("[#{wiki_id}] API Response: #{response.code} #{response.message}")

      response.each_header do |key, value|
        logger.debug("[#{wiki_id}]   #{key}: #{value}")
      end
    end

    private attr_reader :wiki_id
  end
end
