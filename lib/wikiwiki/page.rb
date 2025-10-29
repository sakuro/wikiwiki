# frozen_string_literal: true

module Wikiwiki
  # Represents a wiki page
  #
  # @example
  #   auth = Wikiwiki::Auth.password(password: "admin_password")
  #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
  #   page = wiki.page(page_name: "FrontPage")
  #   page.name # => "FrontPage"
  #   page.source # => "TITLE:FrontPage\n..."
  #   page.timestamp # => 2022-01-01 00:00:00 +0900
  Page = Data.define(:name, :source, :timestamp)

  class Page
    # Reopen the class to add YARD documentation for attributes

    # @!attribute [r] name
    #   @return [String] the page name

    # @!attribute [r] source
    #   @return [String] the page source content

    # @!attribute [r] timestamp
    #   @return [Time] the last update timestamp
  end
end
