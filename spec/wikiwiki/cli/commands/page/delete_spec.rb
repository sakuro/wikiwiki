# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Page::Delete do
  subject(:command) { Wikiwiki::CLI::Commands::Page::Delete.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:delete_page)
  end

  describe "#call" do
    it "deletes the page" do
      out = StringIO.new
      command.call(out:, page_name:, wiki_id:, password:, verbose: false, debug: false)

      expect(wiki).to have_received(:delete_page).with(page_name:)
    end

    context "with --verbose option" do
      it "outputs success message" do
        out = StringIO.new
        command.call(out:, page_name:, wiki_id:, password:, verbose: true, debug: false)
        expect(out.string).to match(/Page '#{page_name}' deleted successfully/)
      end
    end
  end
end
