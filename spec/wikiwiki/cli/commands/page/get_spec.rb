# frozen_string_literal: true

require "securerandom"
require "tempfile"

RSpec.describe Wikiwiki::CLI::Commands::Page::Get do
  subject(:command) { Wikiwiki::CLI::Commands::Page::Get.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:page_content) { "Test page content" }
  let(:page) { instance_double(Wikiwiki::Page, name: page_name, source: page_content) }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:page).with(page_name:).and_return(page)
  end

  describe "#call with output_file" do
    let(:output_file) { File.join(Dir.tmpdir, "test_output_#{SecureRandom.hex(8)}.txt") }

    after do
      FileUtils.rm_f(output_file)
    end

    context "when output file does not exist" do
      it "writes page content to file" do
        out = StringIO.new
        command.call(out:, page_name:, output_file:, wiki_id:, password:, force: false, verbose: false, debug: false)

        expect(File.exist?(output_file)).to be(true)
        expect(File.read(output_file)).to eq(page_content)
      end

      it "outputs message with file size" do
        out = StringIO.new
        command.call(out:, page_name:, output_file:, wiki_id:, password:, force: false, verbose: true, debug: false)
        expect(out.string).to match(/#{page_content.bytesize} bytes/)
      end
    end

    context "when output file already exists" do
      before do
        File.write(output_file, "existing content")
      end

      context "without --force option" do
        it "raises ArgumentError" do
          out = StringIO.new
          expect {
            command.call(out:, page_name:, output_file:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError, /already exists/)
        end

        it "does not overwrite the existing file" do
          out = StringIO.new
          expect {
            command.call(out:, page_name:, output_file:, wiki_id:, password:, force: false, verbose: false, debug: false)
          }.to raise_error(ArgumentError)

          expect(File.read(output_file)).to eq("existing content")
        end
      end

      context "with --force option" do
        it "overwrites the existing file" do
          out = StringIO.new
          command.call(out:, page_name:, output_file:, wiki_id:, password:, force: true, verbose: false, debug: false)

          expect(File.read(output_file)).to eq(page_content)
        end
      end
    end
  end

  describe "#call without output_file" do
    it "outputs page content to stdout" do
      out = StringIO.new
      command.call(out:, page_name:, wiki_id:, password:, verbose: false, debug: false)
      expect(out.string).to eq("#{page_content}\n")
    end
  end
end
