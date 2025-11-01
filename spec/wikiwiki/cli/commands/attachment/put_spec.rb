# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Attachment::Put do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::Put.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:file_path) { "test_upload.txt" }
  let(:file_content) { "Test file content" }
  let(:attachment_name) { "test_upload.txt" }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    File.write(file_path, file_content)
  end

  after do
    FileUtils.rm_f(file_path)
  end

  describe "#call" do
    context "when file size exceeds limit" do
      let(:large_file_path) { "large_file.bin" }
      let(:large_content) { "x" * ((512 * 1024) + 1) } # 512 KiB + 1 byte

      before do
        File.write(large_file_path, large_content)
      end

      after do
        FileUtils.rm_f(large_file_path)
      end

      it "raises ArgumentError" do
        expect {
          command.call(
            page_name:,
            file_path: large_file_path,
            wiki_id:,
            password:,
            force: false,
            verbose: false,
            debug: false
          )
        }.to raise_error(ArgumentError, /exceeds maximum allowed size/)
      end
    end

    context "when attachment does not exist" do
      before do
        allow(wiki).to receive(:attachment_names).with(page_name:).and_return([])
        allow(wiki).to receive(:add_attachment)
      end

      it "uploads the attachment" do
        command.call(page_name:, file_path:, wiki_id:, password:, force: false, verbose: false, debug: false)

        expect(wiki).to have_received(:add_attachment).with(
          page_name:,
          attachment_name:,
          content: file_content
        )
      end

      it "does not check for deletion" do
        allow(wiki).to receive(:delete_attachment)

        command.call(page_name:, file_path:, wiki_id:, password:, force: false, verbose: false, debug: false)

        expect(wiki).not_to have_received(:delete_attachment)
      end
    end

    context "when attachment already exists" do
      before do
        allow(wiki).to receive(:attachment_names).with(page_name:).and_return([attachment_name])
      end

      context "without --force option" do
        it "raises ArgumentError" do
          expect {
            command.call(page_name:, file_path:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError, /already exists/)
        end

        it "does not upload the attachment" do
          allow(wiki).to receive(:add_attachment)

          expect {
            command.call(page_name:, file_path:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError)

          expect(wiki).not_to have_received(:add_attachment)
        end
      end

      context "with --force option" do
        before do
          allow(wiki).to receive(:delete_attachment)
          allow(wiki).to receive(:add_attachment)
        end

        it "deletes the existing attachment first" do
          command.call(page_name:, file_path:, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(wiki).to have_received(:delete_attachment).with(
            page_name:,
            attachment_name:
          )
        end

        it "uploads the new attachment" do
          command.call(page_name:, file_path:, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(wiki).to have_received(:add_attachment).with(
            page_name:,
            attachment_name:,
            content: file_content
          )
        end

        it "deletes before adding (non-atomic operation)" do
          call_order = []
          allow(wiki).to receive(:delete_attachment) { call_order << :delete }
          allow(wiki).to receive(:add_attachment) { call_order << :add }

          command.call(page_name:, file_path:, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(call_order).to eq(%i[delete add])
        end
      end
    end

    context "when page does not exist" do
      before do
        allow(wiki).to receive(:attachment_names).and_raise(Wikiwiki::ResourceNotFoundError)
      end

      it "raises ResourceNotFoundError" do
        expect {
          command.call(page_name:, file_path:, wiki_id:, password:, force: false, verbose: false, debug: false)
        }.to raise_error(Wikiwiki::ResourceNotFoundError)
      end
    end

    context "with custom attachment name" do
      let(:custom_name) { "custom.txt" }

      before do
        allow(wiki).to receive(:attachment_names).with(page_name:).and_return([])
        allow(wiki).to receive(:add_attachment)
      end

      it "uses the custom name" do
        command.call(
          page_name:,
          file_path:,
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
