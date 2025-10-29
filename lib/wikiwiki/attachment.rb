# frozen_string_literal: true

module Wikiwiki
  # Represents a file attachment on a wiki page
  #
  # @example
  #   auth = Wikiwiki::Auth.password("admin_password")
  #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
  #   page = wiki.page("FrontPage")
  #   attachment_names = wiki.attachment_names(page)
  #   attachment = wiki.attachment(page, attachment_names.first)
  #   attachment.name # => "logo.png"
  #   attachment.size # => 12345
  #   attachment.time # => 2022-01-01 00:00:00 +0900
  #   attachment.content # => binary data (decoded)
  Attachment = Data.define(:page_name, :name, :size, :time, :type, :content)
end
