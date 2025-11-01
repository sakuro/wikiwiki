# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      # Attachment-related commands
      module Attachment
        # List attachments on a page
        class List < Base
          desc "List attachments on a page"

          argument :page_name, required: true, desc: "Page name"
          option :json, aliases: ["-j"], type: :boolean, default: false, desc: "Output as JSON"

          # Execute the list command
          #
          # @param page_name [String] name of the page
          # @param options [Hash] command options including wiki_id, auth, json, verbose, out, err
          # @return [void]
          def call(page_name:, out: $stdout, err: $stderr, **options)
            wiki = create_wiki(out:, err:, **options)
            attachment_names = wiki.attachment_names(page_name:)

            if options[:json]
              out.puts Formatter::JSON.new.format(attachment_names)
            else
              attachment_names.each {|name| out.puts name }
              say("#{attachment_names.size} attachments found", out:, **options)
            end
          end
        end
      end

      register "attachment list", Attachment::List
    end
  end
end
