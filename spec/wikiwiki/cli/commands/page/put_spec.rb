# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Page::Put do
  subject(:command) { Wikiwiki::CLI::Commands::Page::Put.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:page_name) { "TestPage" }
  let(:page_source) { "Updated page content" }
  let(:wiki) { instance_double(Wikiwiki::Wiki) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    allow(wiki).to receive(:update_page)
  end

  describe "#call with input_file" do
    let(:input_file) { "test_input.txt" }

    before do
      File.write(input_file, page_source)
    end

    after do
      FileUtils.rm_f(input_file)
    end

    it "reads content from file and updates page" do
      out = StringIO.new
      command.call(out:, page_name:, input_file:, wiki_id:, password:, verbose: false, debug: false)

      expect(wiki).to have_received(:update_page).with(page_name:, source: page_source)
    end

    context "with --verbose option" do
      it "outputs success message" do
        out = StringIO.new
        command.call(out:, page_name:, input_file:, wiki_id:, password:, verbose: true, debug: false)
        expect(out.string).to match(/Page '#{page_name}' updated successfully/)
      end
    end
  end

  describe "#call without input_file" do
    it "reads content from stdin and updates page" do
      out = StringIO.new
      allow($stdin).to receive(:read).and_return(page_source)

      command.call(out:, page_name:, wiki_id:, password:, verbose: false, debug: false)

      expect(wiki).to have_received(:update_page).with(page_name:, source: page_source)
    end
  end

  describe "#call with empty source" do
    it "raises ArgumentError when source is empty" do
      out = StringIO.new
      allow($stdin).to receive(:read).and_return("")

      expect {
        command.call(out:, page_name:, wiki_id:, password:, verbose: false, debug: false)
      }.to raise_error(ArgumentError, "Page source must not be empty. Use 'wikiwiki page delete' to delete a page.")
    end

    it "raises ArgumentError when input file is empty" do
      input_file = "empty_test.txt"
      File.write(input_file, "")

      begin
        out = StringIO.new
        expect {
          command.call(out:, page_name:, input_file:, wiki_id:, password:, verbose: false, debug: false)
        }.to raise_error(ArgumentError, "Page source must not be empty. Use 'wikiwiki page delete' to delete a page.")
      ensure
        FileUtils.rm_f(input_file)
      end
    end
  end
end
