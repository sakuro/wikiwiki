# frozen_string_literal: true

module Wikiwiki
  # Represents a file attachment on a wiki page
  #
  # @example
  #   auth = Wikiwiki::Auth.password(password: "admin_password")
  #   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
  #   page = wiki.page(page_name: "FrontPage")
  #   attachment_names = wiki.attachment_names(page_name: "FrontPage")
  #   attachment = wiki.attachment(page_name: "FrontPage", attachment_name: attachment_names.first)
  #   attachment.name # => "logo.png"
  #   attachment.size # => 12345
  #   attachment.time # => 2022-01-01 00:00:00 +0900
  #   attachment.content # => binary data (decoded)
  Attachment = Data.define(:page_name, :name, :size, :time, :type, :content)

  class Attachment
    # Reopen the class to add YARD documentation for attributes

    # @!attribute [r] page_name
    #   @return [String] the page name this attachment belongs to

    # @!attribute [r] name
    #   @return [String] the attachment file name

    # @!attribute [r] size
    #   @return [Integer] the file size in bytes

    # @!attribute [r] time
    #   @return [Time] the upload time

    # @!attribute [r] type
    #   @return [String] the MIME type

    # @!attribute [r] content
    #   @return [String] the binary file content (decoded from Base64)
  end
end
