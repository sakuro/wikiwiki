# frozen_string_literal: true

RSpec.describe Wikiwiki::CLI do
  # Clean up environment variables before each test
  before do
    ENV.delete("WIKIWIKI_WIKI_ID")
    ENV.delete("WIKIWIKI_API_KEY_ID")
    ENV.delete("WIKIWIKI_SECRET")
    ENV.delete("WIKIWIKI_PASSWORD")
  end

  after do
    ENV.delete("WIKIWIKI_WIKI_ID")
    ENV.delete("WIKIWIKI_API_KEY_ID")
    ENV.delete("WIKIWIKI_SECRET")
    ENV.delete("WIKIWIKI_PASSWORD")
  end

  describe "#run" do
    it "returns 0 on success" do
      Wikiwiki::CLI.new
      dry_cli_double = instance_double(Dry::CLI, call: nil)
      allow(Dry::CLI).to receive(:new).and_return(dry_cli_double)
      cli = Wikiwiki::CLI.new
      expect(cli.run([])).to eq(0)
    end

    it "returns 1 on error" do
      err = StringIO.new
      Wikiwiki::CLI.new(err:)
      dry_cli_double = instance_double(Dry::CLI)
      allow(Dry::CLI).to receive(:new).and_return(dry_cli_double)
      cli = Wikiwiki::CLI.new(err:)
      allow(dry_cli_double).to receive(:call).and_raise(StandardError, "test error")
      expect(cli.run([])).to eq(1)
    end

    it "handles debug mode when --debug is in arguments" do
      out = StringIO.new
      err = StringIO.new
      Wikiwiki::CLI.new(out:, err:)
      dry_cli_double = instance_double(Dry::CLI, call: nil)
      allow(Dry::CLI).to receive(:new).and_return(dry_cli_double)
      cli = Wikiwiki::CLI.new(out:, err:)
      expect(cli.run(["--debug"])).to eq(0)
    end

    it "passes output streams to Dry::CLI" do
      out = StringIO.new
      err = StringIO.new
      dry_cli_double = instance_double(Dry::CLI)
      allow(dry_cli_double).to receive(:call).with(arguments: [], out:, err:)
      allow(Dry::CLI).to receive(:new).and_return(dry_cli_double)
      cli = Wikiwiki::CLI.new(out:, err:)
      cli.run([])
      expect(dry_cli_double).to have_received(:call).with(arguments: [], out:, err:)
    end
  end

  describe "environment variable support" do
    let(:wiki) { instance_double(Wikiwiki::Wiki) }
    let(:auth) { instance_double(Wikiwiki::Auth::Password) }

    before do
      allow(Wikiwiki::Auth).to receive(:password).and_return(auth)
      allow(Wikiwiki::Wiki).to receive(:new).and_return(wiki)
    end

    context "when options are provided" do
      it "uses option values over environment variables" do
        ENV["WIKIWIKI_WIKI_ID"] = "env-wiki"
        ENV["WIKIWIKI_PASSWORD"] = "env-password"

        command = Wikiwiki::CLI::Commands::Base.new
        command.__send__(:create_wiki, wiki_id: "opt-wiki", password: "opt-password", debug: false)

        expect(Wikiwiki::Auth).to have_received(:password).with(password: "opt-password")
        expect(Wikiwiki::Wiki).to have_received(:new).with(wiki_id: "opt-wiki", auth:, logger: an_instance_of(Logger))
      end
    end

    context "when options are not provided" do
      it "falls back to environment variables" do
        ENV["WIKIWIKI_WIKI_ID"] = "env-wiki"
        ENV["WIKIWIKI_PASSWORD"] = "env-password"

        command = Wikiwiki::CLI::Commands::Base.new
        command.__send__(:create_wiki, debug: false)

        expect(Wikiwiki::Auth).to have_received(:password).with(password: "env-password")
        expect(Wikiwiki::Wiki).to have_received(:new).with(wiki_id: "env-wiki", auth:, logger: an_instance_of(Logger))
      end
    end

    context "when neither options nor environment variables are provided" do
      it "raises ArgumentError for missing wiki_id" do
        command = Wikiwiki::CLI::Commands::Base.new
        expect { command.__send__(:create_wiki, password: "test", debug: false) }
          .to raise_error(ArgumentError, /Wiki ID must be provided/)
      end

      it "raises ArgumentError for missing authentication" do
        command = Wikiwiki::CLI::Commands::Base.new
        expect { command.__send__(:create_wiki, wiki_id: "test", debug: false) }
          .to raise_error(ArgumentError, /Either API key.*or --password must be provided/)
      end
    end
  end
end
