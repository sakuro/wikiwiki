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

            # Check if page exists first
            unless page_exists?(wiki, page_name:)
              raise ArgumentError, "Page '#{page_name}' does not exist"
            end

            # Check if attachment exists
            unless attachment_exists?(wiki, page_name:, attachment_name: file_name)
              raise ArgumentError, "Attachment '#{file_name}' does not exist on page '#{page_name}'"
            end

            wiki.delete_attachment(page_name:, attachment_name: file_name)

            say("Attachment '#{file_name}' deleted from page '#{page_name}'", out:, **)
          end

          private def page_exists?(wiki, page_name:) = wiki.page_names.include?(page_name)

          private def attachment_exists?(wiki, page_name:, attachment_name:) = wiki.attachment_names(page_name:).include?(attachment_name)
        end
      end

      register "attachment delete", Attachment::Delete
    end
  end
end
