# frozen_string_literal: true

module Wikiwiki
  class CLI
    # CLI command implementations
    module Commands
      # Page-related commands
      module Page
        # List all pages in the wiki
        class List < Base
          desc "List all pages"

          option :json, aliases: ["-j"], type: :boolean, default: false, desc: "Output as JSON"

          # Execute the list command
          #
          # @param options [Hash] command options including wiki_id, auth, json, verbose, out, err
          # @return [void]
          def call(out: $stdout, err: $stderr, **options)
            wiki = create_wiki(out:, err:, **options)
            page_names = wiki.page_names

            if options[:json]
              out.puts Formatter::JSON.new.format(page_names)
            else
              page_names.each {|name| out.puts name }
              say("#{page_names.size} pages found", out:, **options)
            end
          end
        end
      end

      register "page list", Page::List
    end
  end
end
