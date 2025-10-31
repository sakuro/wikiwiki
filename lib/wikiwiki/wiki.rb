# frozen_string_literal: true

require "base64"
require "digest/md5"
require "erb"
require "logger"
require "time"

module Wikiwiki
  # Represents a Wikiwiki wiki instance
  #
  # @example
  #   auth = Wikiwiki::Auth.password(password: "admin_password")
  #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
  #   wiki.page_names # => ["FrontPage", "SideBar", ...]
  #   page = wiki.page(page_name: "FrontPage")
  class Wiki
    attr_reader :logger

    private attr_reader :api, :wiki_id

    # Initializes a new Wiki instance
    #
    # @param wiki_id [String] the wiki ID
    # @param auth [Wikiwiki::Auth::Password, Wikiwiki::Auth::ApiKey] authentication credentials
    # @param rate_limiter [RateLimiter] rate limiter instance (default: RateLimiter.default)
    # @param logger [Logger] logger instance for API request/response logging (default: Logger.new($stdout))
    # @raise [ArgumentError] if logger is explicitly set to nil
    def initialize(wiki_id:, auth:, rate_limiter: RateLimiter.default, logger: Logger.new($stdout))
      raise ArgumentError, "logger cannot be nil" if logger.nil?

      @wiki_id = wiki_id
      @logger = logger
      @api = API.new(wiki_id:, auth:, logger:, rate_limiter:)
    end

    # Returns the wiki URL
    #
    # @return [URI::HTTPS] the frozen wiki URL
    def url
      @url ||= URI.parse("https://wikiwiki.jp/#{wiki_id}/").freeze
    end

    # Returns the list of all page names in the wiki
    #
    # @return [Array<String>] array of page names
    def page_names = api.get_pages["pages"].map {|p| p["name"] }

    # Retrieves a page by name
    #
    # @param page_name [String] the name of the page
    # @return [Wikiwiki::Page] the page object
    # @raise [Wikiwiki::Error] if the page does not exist
    def page(page_name:)
      encoded_page_name = ERB::Util.url_encode(page_name)
      page_data = api.get_page(encoded_page_name:)
      Page.new(
        name: page_name,
        source: page_data["source"],
        # NOTE: API returns timestamp as ISO8601 string for pages
        timestamp: Time.iso8601(page_data["timestamp"])
      )
    end

    # Updates a page with new content
    #
    # @param page_name [String] the name of the page to update
    # @param source [String] the new page source content
    # @return [void]
    # @raise [Wikiwiki::Error] if the update fails
    def update_page(page_name:, source:)
      encoded_page_name = ERB::Util.url_encode(page_name)
      api.put_page(encoded_page_name:, source:)
    end

    # Retrieves attachment file names on a page
    #
    # @param page_name [String] the name of the page
    # @return [Array<String>] array of attachment file names
    # @raise [Wikiwiki::Error] if the request fails
    def attachment_names(page_name:)
      encoded_page_name = ERB::Util.url_encode(page_name)
      attachments_data = api.get_attachments(encoded_page_name:)
      attachments = attachments_data["attachments"]
      # API returns [] when no attachments, or Hash when attachments exist
      attachments.is_a?(Hash) ? attachments.keys : []
    end

    # Retrieves a specific attachment on a page
    #
    # @param page_name [String] the name of the page
    # @param attachment_name [String] the name of the attachment file
    # @param rev [String, nil] optional MD5 hash to retrieve a specific revision
    # @return [Wikiwiki::Attachment] the attachment object with decoded file data
    # @raise [Wikiwiki::Error] if the attachment does not exist
    # @raise [ArgumentError] if rev is not a valid MD5 hash format
    def attachment(page_name:, attachment_name:, rev: nil)
      if rev && !rev.match?(/\A[0-9a-f]{32}\z/i)
        raise ArgumentError, "rev must be a valid MD5 hash (32 hexadecimal characters)"
      end

      encoded_page_name = ERB::Util.url_encode(page_name)
      encoded_attachment_name = ERB::Util.url_encode(attachment_name)
      data = api.get_attachment(encoded_page_name:, encoded_attachment_name:, rev:)

      content = Base64.strict_decode64(data["src"])

      if content.bytesize != data["size"]
        raise ContentIntegrityError, "Size mismatch: expected #{data["size"]}, got #{content.bytesize}"
      end

      calculated_md5 = Digest::MD5.hexdigest(content)
      if calculated_md5 != data["md5hash"]
        raise ContentIntegrityError, "MD5 hash mismatch: expected #{data["md5hash"]}, got #{calculated_md5}"
      end

      Attachment.new(
        page_name: data["page"],
        name: data["file"],
        size: data["size"],
        # NOTE: API returns time as Unix timestamp (integer) for attachments, not ISO8601 string
        time: Time.at(data["time"]),
        type: data["type"],
        content:
      )
    end

    # Adds an attachment to a page
    #
    # @param page_name [String] the name of the page
    # @param attachment_name [String] the name of the file
    # @param content [String] the binary file content
    # @return [void]
    # @raise [Wikiwiki::Error] if the upload fails
    def add_attachment(page_name:, attachment_name:, content:)
      encoded_page_name = ERB::Util.url_encode(page_name)
      encoded_content = Base64.strict_encode64(content)
      api.put_attachment(encoded_page_name:, attachment_name:, encoded_content:)
    end

    # Deletes an attachment from a page
    #
    # @param page_name [String] the name of the page
    # @param attachment_name [String] the name of the attachment file
    # @return [void]
    # @raise [Wikiwiki::Error] if the deletion fails
    def delete_attachment(page_name:, attachment_name:)
      encoded_page_name = ERB::Util.url_encode(page_name)
      encoded_attachment_name = ERB::Util.url_encode(attachment_name)
      api.delete_attachment(encoded_page_name:, encoded_attachment_name:)
    end
  end
end
