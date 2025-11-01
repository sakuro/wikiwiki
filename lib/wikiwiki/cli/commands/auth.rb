# frozen_string_literal: true

module Wikiwiki
  class CLI
    module Commands
      # Authenticate and output JWT token
      class Auth < Base
        desc "Authenticate and output JWT token"

        option :json, aliases: ["-j"], type: :boolean, default: false, desc: "Output as JSON"

        # Execute the auth command
        #
        # @param options [Hash] command options including wiki_id, auth credentials, json, verbose, out, err
        # @return [void]
        def call(out: $stdout, err: $stderr, **options)
          wiki = create_wiki(out:, err:, **options)
          token = wiki.token

          if options[:json]
            out.puts Formatter::JSON.new.format({"token" => token})
          else
            out.puts token
            say("Authentication successful", out:, **options)
          end
        end
      end

      register "auth", Auth
    end
  end
end
