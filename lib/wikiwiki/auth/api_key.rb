# frozen_string_literal: true

module Wikiwiki
  module Auth
    # API key-based authentication credentials
    #
    # @example
    #   auth = Wikiwiki::Auth::ApiKey.new(api_key_id: "key_id", secret: "secret")
    #   auth.endpoint # => "::api/auth"
    #   auth.request_body # => {api_key_id: "key_id", secret: "secret"}
    ApiKey = Data.define(:api_key_id, :secret)

    # API key-based authentication credentials
    class ApiKey
      # Returns the authentication endpoint path
      #
      # @return [String] endpoint path
      def endpoint = "::api/auth"

      # Returns the request body for authentication
      #
      # @return [Hash] request body
      def request_body = {api_key_id:, secret:}
    end
  end
end
