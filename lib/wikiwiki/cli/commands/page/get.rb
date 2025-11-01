# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Page
        # Get page content
        class Get < Base
          desc "Get page content"

          argument :page_name, required: true, desc: "Page name"
          argument :output_file, required: false, desc: "Output file (stdout if omitted)"
          option :force, aliases: ["-f"], type: :boolean, default: false, desc: "Overwrite existing file"

          # Execute the get command
          #
          # @param page_name [String] name of the page to get
          # @param output_file [String, nil] optional output file path
          # @param force [Boolean] whether to overwrite existing file
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          def call(page_name:, output_file: nil, force: false, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            # Check if output file exists when not forcing
            if output_file && File.exist?(output_file) && !force
              raise ArgumentError, "File '#{output_file}' already exists. Use --force to overwrite."
            end

            page = wiki.page(page_name:)

            if output_file
              File.write(output_file, page.source)
              say("Page '#{page_name}' (#{page.source.bytesize} bytes) saved to #{output_file}", out:, **)
            else
              out.puts page.source
            end
          end
        end
      end

      register "page get", Page::Get
    end
  end
end
