# frozen_string_literal: true

require "tempfile"

RSpec.describe Wikiwiki::CLI::Commands::Attachment::Put do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::Put.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:file_content) { "Test file content" }
  let(:file_path) do
    file = Tempfile.new(["test_upload", ".txt"])
    file.write(file_content)
    file.close
    file
  end
  let(:attachment_name) { File.basename(file_path.path) }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
  end

  after do
    file_path.close!
  end

  describe "#call" do
    context "when file size exceeds limit" do
      let(:large_content) { "x" * ((512 * 1024) + 1) } # 512 KiB + 1 byte
      let(:large_file_path) do
        file = Tempfile.new(["large_file", ".bin"])
        file.write(large_content)
        file.close
        file
      end

      after do
        large_file_path.close!
      end

      it "raises ArgumentError" do
        expect {
          command.call(
            page_name:,
            file_path: large_file_path.path,
            wiki_id:,
            password:,
            force: false,
            verbose: false,
            debug: false
          )
        }.to raise_error(ArgumentError, /exceeds maximum allowed size/)
      end
    end

    context "when uploading new attachment" do
      before do
        allow(wiki).to receive(:add_attachment)
      end

      it "uploads the attachment" do
        command.call(page_name:, file_path: file_path.path, wiki_id:, password:, force: false, verbose: false, debug: false)

        expect(wiki).to have_received(:add_attachment).with(
          page_name:,
          attachment_name:,
          content: file_content
        )
      end
    end

    context "when attachment already exists" do
      before do
        allow(wiki).to receive(:add_attachment).and_raise(Wikiwiki::ConflictError, "API request failed: 409 Conflict")
      end

      context "without --force option" do
        it "raises ArgumentError" do
          expect {
            command.call(page_name:, file_path: file_path.path, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError, /already exists/)
        end
      end

      context "with --force option" do
        it "deletes and re-uploads the attachment" do
          call_count = 0
          allow(wiki).to receive(:add_attachment) do
            call_count += 1
            raise Wikiwiki::ConflictError, "API request failed: 409 Conflict" if call_count == 1

            nil
          end
          allow(wiki).to receive(:delete_attachment)

          command.call(page_name:, file_path: file_path.path, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(wiki).to have_received(:delete_attachment).with(
            page_name:,
            attachment_name:
          )
          expect(wiki).to have_received(:add_attachment).twice
        end
      end
    end

    context "with custom attachment name" do
      let(:custom_name) { "custom.txt" }

      before do
        allow(wiki).to receive(:add_attachment)
      end

      it "uses the custom name" do
        command.call(
          page_name:,
          file_path: file_path.path,
          name: custom_name,
          wiki_id:,
          password:,
          force: false,
          verbose: false,
          debug: false
        )

        expect(wiki).to have_received(:add_attachment).with(
          page_name:,
          attachment_name: custom_name,
          content: file_content
        )
      end
    end
  end
end
