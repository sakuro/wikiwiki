# frozen_string_literal: true

require "json"

module Wikiwiki
  class CLI
    module Formatter
      # JSON output formatter for CLI commands
      class JSON
        # Format data as pretty-printed JSON
        #
        # @param data [Object] data to format (Hash, Array, etc.)
        # @return [String] formatted JSON string
        def format(data) = ::JSON.pretty_generate(data)
      end
    end
  end
end
