# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Attachment
        # Download attachment from a page
        class Get < Base
          desc "Download attachment from a page"

          argument :page_name, required: true, desc: "Page name"
          argument :file_name, required: true, desc: "Attachment file name"
          option :directory, aliases: ["-d"], desc: "Download directory (current directory if omitted)"
          option :force, aliases: ["-f"], type: :boolean, default: false, desc: "Overwrite existing file"

          # Execute the get command
          #
          # @param page_name [String] name of the page
          # @param file_name [String] name of the attachment file
          # @param directory [String, nil] optional download directory
          # @param force [Boolean] whether to overwrite existing file
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          def call(page_name:, file_name:, directory: nil, force: false, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            output_path = directory ? File.join(directory, file_name) : file_name

            if File.exist?(output_path) && !force
              raise ArgumentError, "File '#{output_path}' already exists. Use --force to overwrite."
            end

            attachment = wiki.attachment(page_name:, attachment_name: file_name)
            File.binwrite(output_path, attachment.content)

            say("Attachment '#{file_name}' (#{attachment.content.bytesize} bytes) saved to #{output_path}", out:, **)
          end
        end
      end

      register "attachment get", Attachment::Get
    end
  end
end
