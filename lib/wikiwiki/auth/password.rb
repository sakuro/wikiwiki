# frozen_string_literal: true

module Wikiwiki
  module Auth
    # Password-based authentication credentials
    #
    # @example
    #   auth = Wikiwiki::Auth::Password.new(password: "admin_password")
    #   auth.to_h # => {password: "admin_password"}
    Password = Data.define(:password)

    class Password
      # Reopen the class to add YARD documentation for attributes

      # @!attribute [r] password
      #   @return [String] the admin password
    end
  end
end
