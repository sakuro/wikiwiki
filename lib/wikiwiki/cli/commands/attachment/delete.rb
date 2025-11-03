# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Attachment
        # Delete attachment from a page
        class Delete < Base
          desc "Delete attachment from a page"

          argument :page_name, required: true, desc: "Page name"
          argument :file_name, required: true, desc: "Attachment file name"

          # Execute the delete command
          #
          # @param page_name [String] name of the page
          # @param file_name [String] name of the attachment file to delete
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          def call(page_name:, file_name:, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            wiki.delete_attachment(page_name:, attachment_name: file_name)

            say("Attachment '#{file_name}' deleted from page '#{page_name}'", out:, **)
          end
        end
      end

      register "attachment delete", Attachment::Delete
    end
  end
end
