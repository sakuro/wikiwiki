# frozen_string_literal: true

module Wikiwiki
  class CLI
    # CLI command implementations
    #
    # This module serves as a namespace for all CLI commands.
    # Commands are organized into submodules (Page, Attachment) for better organization.
    module Commands
      # Base command class with global options
      class Base < Dry::CLI::Command
        option :wiki_id, aliases: ["-w"], desc: "Wiki ID (or set WIKIWIKI_WIKI_ID)"
        option :api_key_id, desc: "API Key ID for authentication (or set WIKIWIKI_API_KEY_ID)"
        option :secret, desc: "API Key Secret for authentication (or set WIKIWIKI_SECRET)"
        option :password, desc: "Password for authentication (or set WIKIWIKI_PASSWORD)"
        option :verbose, aliases: ["-v"], type: :boolean, default: false, desc: "Verbose output"
        option :debug, type: :boolean, default: false, desc: "Debug mode"

        private def create_wiki(wiki_id: nil, api_key_id: nil, secret: nil, password: nil, debug: false, out: $stdout, err: $stderr, **)
          # Fallback to environment variables if options are not provided
          wiki_id ||= ENV.fetch("WIKIWIKI_WIKI_ID", nil)
          api_key_id ||= ENV.fetch("WIKIWIKI_API_KEY_ID", nil)
          secret ||= ENV.fetch("WIKIWIKI_SECRET", nil)
          password ||= ENV.fetch("WIKIWIKI_PASSWORD", nil)

          raise ArgumentError, "Wiki ID must be provided via --wiki-id or WIKIWIKI_WIKI_ID" unless wiki_id

          auth = if api_key_id && secret
                   Auth.api_key(api_key_id:, secret:)
                 elsif password
                   Auth.password(password:)
                 else
                   raise ArgumentError, "Either API key (--api-key-id and --secret) or --password must be provided (via options or environment variables)"
                 end

          logger = create_logger(debug:, out:, err:)
          Wiki.new(wiki_id:, auth:, logger:)
        end

        private def create_logger(debug:, out: $stdout, err: $stderr)
          if debug
            Logger.new(err, level: Logger::DEBUG)
          elsif out.tty?
            Logger.new(err, level: Logger::WARN)
          else
            Logger.new(IO::NULL)
          end
        end

        private def verbose?(verbose:, json: false, **) = verbose && !json

        private def say(message, verbose:, out: $stdout, **)
          return unless verbose?(verbose:)

          out.puts message
        end
      end
    end
  end
end
