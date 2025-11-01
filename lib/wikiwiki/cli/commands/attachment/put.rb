# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      module Attachment
        # Upload attachment to a page
        class Put < Base
          desc "Upload attachment to a page"

          MAX_ATTACHMENT_SIZE = 512 * 1024 # 512 KiB
          private_constant :MAX_ATTACHMENT_SIZE

          argument :page_name, required: true, desc: "Page name"
          argument :file_path, required: true, desc: "Local file path"
          option :name, aliases: ["-n"], desc: "Attachment name (inferred from file path if omitted)"
          option :force, aliases: ["-f"], type: :boolean, default: false, desc: "Overwrite existing attachment"

          # Execute the put command
          #
          # @param page_name [String] name of the page
          # @param file_path [String] local file path to upload
          # @param name [String, nil] optional attachment name (inferred from file_path if nil)
          # @param force [Boolean] whether to overwrite existing attachment
          # @param out [IO] output stream
          # @param err [IO] error stream
          # @return [void]
          def call(page_name:, file_path:, name: nil, force: false, out: $stdout, err: $stderr, **)
            wiki = create_wiki(out:, err:, **)

            attachment_name = name || File.basename(file_path)
            content = File.binread(file_path)

            if content.bytesize > MAX_ATTACHMENT_SIZE
              raise ArgumentError, "File size (#{content.bytesize} bytes) exceeds maximum allowed size (#{MAX_ATTACHMENT_SIZE} bytes / 512 KiB)"
            end

            if attachment_exists?(wiki, page_name:, attachment_name:)
              raise ArgumentError, "Attachment '#{attachment_name}' already exists. Use --force to overwrite." unless force

              begin
                wiki.delete_attachment(page_name:, attachment_name:)
              rescue ResourceNotFoundError
                # Already deleted by another process, continue
              end
            end

            wiki.add_attachment(page_name:, attachment_name:, content:)

            say("Attachment '#{attachment_name}' uploaded to page '#{page_name}'", out:, **)
          end

          private def attachment_exists?(wiki, page_name:, attachment_name:) = wiki.attachment_names(page_name:).include?(attachment_name)
        end
      end

      register "attachment put", Attachment::Put
    end
  end
end
