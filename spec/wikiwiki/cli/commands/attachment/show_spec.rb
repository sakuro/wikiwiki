# frozen_string_literal: true

require "json"

RSpec.describe Wikiwiki::CLI::Commands::Attachment::Show do
  subject(:command) { Wikiwiki::CLI::Commands::Attachment::Show.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:file_name) { "test.txt" }
  let(:attachment_time) { Time.new(2024, 1, 1, 12, 0, 0, "+00:00") }
  let(:attachment) do
    Wikiwiki::Attachment.new(
      page_name:,
      name: file_name,
      size: 1234,
      time: attachment_time,
      type: "text/plain",
      content: "test content"
    )
  end
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:attachment).with(page_name:, attachment_name: file_name).and_return(attachment)
  end

  describe "#call" do
    context "without --json option" do
      it "outputs attachment metadata in human-readable format" do
        expected_output = <<~OUTPUT
          Page: #{page_name}
          Name: #{file_name}
          Size: 1234 bytes
          Time: #{attachment_time.iso8601}
          Type: text/plain
        OUTPUT

        out = StringIO.new
        command.call(out:, page_name:, file_name:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to eq(expected_output)
      end

      context "with --verbose option" do
        it "outputs summary message" do
          out = StringIO.new
          command.call(out:, page_name:, file_name:, wiki_id:, password:, json: false, verbose: true, debug: false)
          expect(out.string).to match(/Attachment metadata retrieved/)
        end
      end
    end

    context "with --json option" do
      it "outputs attachment metadata as JSON" do
        out = StringIO.new
        command.call(out:, page_name:, file_name:, wiki_id:, password:, json: true, verbose: false, debug: false)

        parsed = JSON.parse(out.string)
        expect(parsed["page_name"]).to eq(page_name)
        expect(parsed["name"]).to eq(file_name)
        expect(parsed["size"]).to eq(1234)
        expect(parsed["time"]).to eq(attachment_time.iso8601)
        expect(parsed["type"]).to eq("text/plain")
        expect(parsed).not_to have_key("content")
      end

      it "does not output summary message even with --verbose" do
        out = StringIO.new
        command.call(out:, page_name:, file_name:, wiki_id:, password:, json: true, verbose: true, debug: false)
        expect(out.string).not_to match(/Attachment metadata retrieved/)
      end
    end
  end
end
