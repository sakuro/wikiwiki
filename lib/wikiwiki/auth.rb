# frozen_string_literal: true

module Wikiwiki
  # Authentication credentials module
  #
  # Provides factory methods for creating authentication objects
  module Auth
    # Create password-based authentication credentials
    #
    # @param password [String] admin password
    # @return [Password] password authentication object
    def self.password(password:) = Password.new(password:)

    # Create API key-based authentication credentials
    #
    # @param api_key_id [String] API key ID
    # @param secret [String] secret key
    # @return [ApiKey] API key authentication object
    def self.api_key(api_key_id:, secret:) = ApiKey.new(api_key_id:, secret:)
  end
end
