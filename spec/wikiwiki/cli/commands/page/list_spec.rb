# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Page::List do
  subject(:command) { Wikiwiki::CLI::Commands::Page::List.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_names) { %w[Page1 Page2 Page3] }
  let(:wiki) { instance_double(Wikiwiki::Wiki, page_names:) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).with(password:).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
  end

  describe "#call" do
    context "without --json option" do
      it "outputs page names line by line" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to eq("Page1\nPage2\nPage3\n")
      end

      context "with --verbose option" do
        it "outputs page names and summary message" do
          out = StringIO.new
          command.call(out:, wiki_id:, password:, json: false, verbose: true, debug: false)
          expect(out.string).to eq("Page1\nPage2\nPage3\n3 pages found\n")
        end
      end
    end

    context "with --json option" do
      it "outputs page names as JSON array" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: true, verbose: false, debug: false)
        expect(out.string).to include('"Page1"', '"Page2"', '"Page3"')
      end

      it "does not output verbose message even with --verbose" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: true, verbose: true, debug: false)
        expect(out.string).not_to include("pages found")
      end
    end
  end
end
