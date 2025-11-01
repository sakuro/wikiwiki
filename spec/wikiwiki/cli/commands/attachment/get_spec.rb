# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Attachment::Get do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::Get.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:file_name) { "test.txt" }
  let(:file_content) { "test attachment content" }
  let(:attachment) do
    Wikiwiki::Attachment.new(
      page_name:,
      name: file_name,
      size: file_content.bytesize,
      time: Time.now,
      type: "text/plain",
      content: file_content
    )
  end
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:attachment).with(page_name:, attachment_name: file_name).and_return(attachment)
  end

  after do
    FileUtils.rm_f(file_name)
    FileUtils.rm_f("custom_dir/#{file_name}")
    FileUtils.rm_rf("custom_dir")
  end

  describe "#call" do
    context "when output file does not exist" do
      it "downloads attachment to current directory" do
        out = StringIO.new
        command.call(out:, page_name:, file_name:, wiki_id:, password:, force: false, verbose: false, debug: false)

        expect(File.exist?(file_name)).to be(true)
        expect(File.read(file_name)).to eq(file_content)
      end

      it "outputs message with file size" do
        out = StringIO.new
        command.call(out:, page_name:, file_name:, wiki_id:, password:, force: false, verbose: true, debug: false)
        expect(out.string).to match(/#{file_content.bytesize} bytes/)
      end
    end

    context "when output file already exists" do
      before do
        File.write(file_name, "existing content")
      end

      context "without --force option" do
        it "raises ArgumentError" do
          out = StringIO.new
          expect {
            command.call(out:, page_name:, file_name:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError, /already exists/)
        end

        it "does not overwrite the existing file" do
          out = StringIO.new
          expect {
            command.call(out:, page_name:, file_name:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError)

          expect(File.read(file_name)).to eq("existing content")
        end
      end

      context "with --force option" do
        it "overwrites the existing file" do
          out = StringIO.new
          command.call(out:, page_name:, file_name:, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(File.read(file_name)).to eq(file_content)
        end
      end
    end

    context "with --directory option" do
      let(:custom_dir) { "custom_dir" }

      before do
        FileUtils.mkdir_p(custom_dir)
      end

      it "downloads attachment to specified directory" do
        out = StringIO.new
        command.call(
          out:,
          page_name:,
          file_name:,
          directory: custom_dir,
          wiki_id:,
          password:,
          force: false,
          verbose: false,
          debug: false
        )

        expect(File.exist?(File.join(custom_dir, file_name))).to be(true)
        expect(File.read(File.join(custom_dir, file_name))).to eq(file_content)
      end

      context "when file exists in specified directory" do
        before do
          File.write(File.join(custom_dir, file_name), "existing content")
        end

        it "raises error without --force" do
          out = StringIO.new
          expect {
            command.call(
              out:,
              page_name:,
              file_name:,
              directory: custom_dir,
              wiki_id:,
              password:,
              force: false,
              verbose: false,
              debug: false
            )
          }.to raise_error(ArgumentError, /already exists/)
        end

        it "overwrites with --force" do
          out = StringIO.new
          command.call(
            out:,
            page_name:,
            file_name:,
            directory: custom_dir,
            wiki_id:,
            password:,
            force: true,
            verbose: false,
            debug: false
          )

          expect(File.read(File.join(custom_dir, file_name))).to eq(file_content)
        end
      end
    end
  end
end
