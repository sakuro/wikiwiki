# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Page::Show do
  subject(:command) { Wikiwiki::CLI::Commands::Page::Show.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:timestamp) { Time.new(2025, 1, 1, 12, 0, 0, "+00:00") }
  let(:page) { instance_double(Wikiwiki::Page, name: page_name, timestamp:, source: "test content") }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).with(password:).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:page).with(page_name:).and_return(page)
  end

  describe "#call" do
    context "without --json option" do
      it "outputs page metadata in human-readable format" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to match(/Name: TestPage/)
        expect(out.string).to match(/Timestamp: 2025-01-01T12:00:00\+00:00/)
        expect(out.string).to match(/Source size: 12 bytes/)
      end

      context "with --verbose option" do
        it "outputs metadata and summary message" do
          out = StringIO.new
          command.call(out:, page_name:, wiki_id:, password:, json: false, verbose: true, debug: false)
          expect(out.string).to match(/Page metadata retrieved/)
        end
      end
    end

    context "with --json option" do
      it "outputs page metadata as JSON" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: true, verbose: false, debug: false)
        expect(out.string).to include('"name"', '"TestPage"', '"timestamp"', '"source_size"')
      end

      it "does not output verbose message even with --verbose" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, json: true, verbose: true, debug: false)
        expect(out.string).not_to include("metadata retrieved")
      end
    end
  end
end
