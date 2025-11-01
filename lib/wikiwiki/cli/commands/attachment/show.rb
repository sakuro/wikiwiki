# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Attachment
        # Show attachment metadata
        class Show < Base
          desc "Show attachment metadata"

          argument :page_name, required: true, desc: "Page name"
          argument :file_name, required: true, desc: "Attachment file name"
          option :json, aliases: ["-j"], type: :boolean, default: false, desc: "Output as JSON"

          # Execute the show command
          #
          # @param page_name [String] name of the page
          # @param file_name [String] name of the attachment file
          # @param options [Hash] command options including wiki_id, auth, json, verbose, out, err
          # @return [void]
          def call(page_name:, file_name:, out: $stdout, err: $stderr, **options)
            wiki = create_wiki(out:, err:, **options)
            attachment = wiki.attachment(page_name:, attachment_name: file_name)

            metadata = attachment.to_h.except(:content).transform_values {|v| v.is_a?(Time) ? v.iso8601 : v }

            if options[:json]
              out.puts Formatter::JSON.new.format(metadata)
            else
              out.puts "Page: #{metadata[:page_name]}"
              out.puts "Name: #{metadata[:name]}"
              out.puts "Size: #{metadata[:size]} bytes"
              out.puts "Time: #{metadata[:time]}"
              out.puts "Type: #{metadata[:type]}"
              say("Attachment metadata retrieved", out:, **options)
            end
          end
        end
      end

      register "attachment show", Attachment::Show
    end
  end
end
