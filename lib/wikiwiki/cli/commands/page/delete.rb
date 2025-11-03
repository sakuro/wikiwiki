# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Page
        # Delete a page
        class Delete < Base
          desc "Delete a page"

          argument :page_name, required: true, desc: "Page name"

          # Execute the delete command
          #
          # @param page_name [String] name of the page to delete
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          def call(page_name:, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            wiki.delete_page(page_name:)

            say("Page '#{page_name}' deleted successfully", out:, **)
          end
        end
      end

      register "page delete", Page::Delete
    end
  end
end
