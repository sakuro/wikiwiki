# frozen_string_literal: true

module Wikiwiki
  # Represents a wiki page
  #
  # @example
  #   auth = Wikiwiki::Auth.password("admin_password")
  #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
  #   page = wiki.page("FrontPage")
  #   page.name # => "FrontPage"
  #   page.source # => "TITLE:FrontPage\n..."
  #   page.timestamp # => 2022-01-01 00:00:00 +0900
  Page = Data.define(:name, :source, :timestamp)
end
