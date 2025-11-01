# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Page
        # Show page metadata
        class Show < Base
          desc "Show page metadata"

          argument :page_name, required: true, desc: "Page name"
          option :json, aliases: ["-j"], type: :boolean, default: false, desc: "Output as JSON"

          # Execute the show command
          #
          # @param page_name [String] name of the page to show
          # @param options [Hash] command options including wiki_id, auth, json, verbose, out, err
          # @return [void]
          def call(page_name:, out: $stdout, err: $stderr, **options)
            wiki = create_wiki(out:, err:, **options)
            page = wiki.page(page_name:)

            metadata = {
              "name" => page.name,
              "timestamp" => page.timestamp.iso8601,
              "source_size" => page.source.bytesize
            }

            if options[:json]
              out.puts Formatter::JSON.new.format(metadata)
            else
              out.puts "Name: #{metadata["name"]}"
              out.puts "Timestamp: #{metadata["timestamp"]}"
              out.puts "Source size: #{metadata["source_size"]} bytes"
              say("Page metadata retrieved", out:, **options)
            end
          end
        end
      end

      register "page show", Page::Show
    end
  end
end
