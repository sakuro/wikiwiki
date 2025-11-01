# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Attachment::Delete do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::Delete.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:file_name) { "test.txt" }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:page_names).and_return([page_name])
    allow(wiki).to receive(:attachment_names).with(page_name:).and_return([file_name])
    allow(wiki).to receive(:delete_attachment)
  end

  describe "#call" do
    it "deletes the attachment" do
      out = StringIO.new
      command.call(out:, page_name:, file_name:, wiki_id:, password:, verbose: false, debug: false)

      expect(wiki).to have_received(:delete_attachment).with(
        page_name:,
        attachment_name: file_name
      )
    end

    it "outputs success message with verbose" do
      out = StringIO.new
      command.call(out:, page_name:, file_name:, wiki_id:, password:, verbose: true, debug: false)
      expect(out.string).to match(/Attachment '#{file_name}' deleted from page '#{page_name}'/)
    end

    context "when page does not exist" do
      before do
        allow(wiki).to receive(:page_names).and_return([])
      end

      it "raises ArgumentError with page not found message" do
        out = StringIO.new
        expect {
          command.call(out:, page_name:, file_name:, wiki_id:, password:, verbose: false, debug: false)
        }.to raise_error(ArgumentError, /Page '#{page_name}' does not exist/)
      end
    end

    context "when attachment does not exist" do
      before do
        allow(wiki).to receive(:attachment_names).with(page_name:).and_return([])
      end

      it "raises ArgumentError with attachment not found message" do
        out = StringIO.new
        expect {
          command.call(out:, page_name:, file_name:, wiki_id:, password:, verbose: false, debug: false)
        }.to raise_error(ArgumentError, /Attachment '#{file_name}' does not exist/)
      end
    end
  end
end
