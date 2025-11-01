# frozen_string_literal: true

require "json"

RSpec.describe Wikiwiki::CLI::Commands::Attachment::List do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::List.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:attachment_names) { %w[file1.txt file2.pdf file3.png] }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:attachment_names).with(page_name:).and_return(attachment_names)
  end

  describe "#call" do
    context "without --json option" do
      it "outputs attachment names to stdout" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to eq("file1.txt\nfile2.pdf\nfile3.png\n")
      end

      context "with --verbose option" do
        it "outputs summary message" do
          out = StringIO.new
          command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: true, debug: false)
          expect(out.string).to eq("file1.txt\nfile2.pdf\nfile3.png\n3 attachments found\n")
        end
      end
    end

    context "with --json option" do
      it "outputs JSON array" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: true, verbose: false, debug: false)
        expect(JSON.parse(out.string)).to eq(attachment_names)
      end

      it "does not output summary message even with --verbose" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: true, verbose: true, debug: false)
        expect(JSON.parse(out.string)).to eq(attachment_names)
      end
    end

    context "when no attachments exist" do
      let(:attachment_names) { [] }

      it "outputs nothing without --verbose" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to be_empty
      end

      it "outputs summary with --verbose" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: true, debug: false)
        expect(out.string).to eq("0 attachments found\n")
      end

      it "outputs empty JSON array with --json" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: true, verbose: false, debug: false)
        expect(JSON.parse(out.string)).to eq([])
      end
    end
  end
end
