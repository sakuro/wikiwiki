# frozen_string_literal: true

module Wikiwiki
  module Auth
    # API key-based authentication credentials
    #
    # @example
    #   auth = Wikiwiki::Auth::ApiKey.new(api_key_id: "key_id", secret: "secret")
    #   auth.to_h # => {api_key_id: "key_id", secret: "secret"}
    ApiKey = Data.define(:api_key_id, :secret)

    class ApiKey
      # Reopen the class to add YARD documentation for attributes

      # @!attribute [r] api_key_id
      #   @return [String] the API key ID

      # @!attribute [r] secret
      #   @return [String] the secret key
    end
  end
end
