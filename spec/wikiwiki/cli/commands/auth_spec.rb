# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI::Commands::Auth do
  subject(:command) { Wikiwiki::CLI::Commands::Auth.new }

  let(:wiki_id) { "test-wiki" }
  let(:password) { "test-password" }
  let(:token) { "jwt_token_123" }
  let(:wiki) { instance_double(Wikiwiki::Wiki, token:) }

  before do
    allow(Wikiwiki::Auth).to receive(:password).and_return(double)
    allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
  end

  describe "#call" do
    context "without --json option" do
      it "outputs the token" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: false, verbose: false, debug: false)
        expect(out.string).to include(token)
      end

      context "with --verbose option" do
        it "outputs token and success message" do
          out = StringIO.new
          command.call(out:, wiki_id:, password:, json: false, verbose: true, debug: false)
          expect(out.string).to include(token)
          expect(out.string).to match(/Authentication successful/)
        end
      end
    end

    context "with --json option" do
      it "outputs token as JSON" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: true, verbose: false, debug: false)

        parsed = JSON.parse(out.string)
        expect(parsed["token"]).to eq(token)
      end

      it "does not output success message even with --verbose" do
        out = StringIO.new
        command.call(out:, wiki_id:, password:, json: true, verbose: true, debug: false)
        expect(out.string).not_to match(/Authentication successful/)
      end
    end
  end
end
