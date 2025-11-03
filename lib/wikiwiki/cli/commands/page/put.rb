# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Page
        # Upload/update page content (creates if not exists)
        class Put < Base
          desc "Upload/update page content (creates if not exists)"

          argument :page_name, required: true, desc: "Page name"
          argument :input_file, required: false, desc: "Input file (stdin if omitted)"

          # Execute the put command
          #
          # @param page_name [String] name of the page to update
          # @param input_file [String, nil] optional input file path (uses stdin if nil)
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          # @raise [ArgumentError] if source content is empty
          # @note To delete a page, use `wikiwiki page delete` instead
          def call(page_name:, input_file: nil, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            source = if input_file
                       File.read(input_file)
                     else
                       $stdin.read
                     end

            raise ArgumentError, "Page source must not be empty. Use 'wikiwiki page delete' to delete a page." if source.empty?

            wiki.update_page(page_name:, source:)

            say("Page '#{page_name}' updated successfully", out:, **)
          end
        end
      end

      register "page put", Page::Put
    end
  end
end
