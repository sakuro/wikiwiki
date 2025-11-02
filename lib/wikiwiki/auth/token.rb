# frozen_string_literal: true

module Wikiwiki
  module Auth
    # Token-based authentication using a pre-obtained JWT token
    #
    # This allows using a previously obtained authentication token without
    # re-authenticating with password or API key credentials.
    #
    # @example
    #   token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    #   auth = Wikiwiki::Auth.token(token: token)
    #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth: auth)
    Token = Data.define(:token)

    class Token
      # Reopen the class to add YARD documentation for attributes

      # @!attribute [r] token
      #   @return [String] the JWT token
    end
  end
end
