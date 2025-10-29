# frozen_string_literal: true

module Wikiwiki
  module Auth
    # Password-based authentication credentials
    #
    # @example
    #   auth = Wikiwiki::Auth::Password.new(password: "admin_password")
    #   auth.endpoint # => "auth"
    #   auth.request_body # => {password: "admin_password"}
    Password = Data.define(:password)

    class Password
      # Reopen the class to add YARD documentation for attributes

      # @!attribute [r] password
      #   @return [String] the admin password

      # Returns the authentication endpoint path
      #
      # @return [String] endpoint path
      def endpoint = "auth"

      # Returns the request body for authentication
      #
      # @return [Hash] request body
      def request_body = {password:}
    end
  end
end
