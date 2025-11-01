# frozen_string_literal: true

require "dry/cli"
require "logger"

module Wikiwiki
  # Command-line interface for Wikiwiki
  #
  # Provides commands for managing wiki pages and attachments through the terminal.
  # Supports authentication via API key or password, with configurable logging and output modes.
  class CLI
    # Run the CLI with given arguments
    #
    # @param argv [Array<String>] command-line arguments
    # @param out [IO] standard output (defaults to $stdout)
    # @param err [IO] error output (defaults to $stderr)
    # @return [Integer] exit code (0 for success, 1 for error)
    def initialize(out: $stdout, err: $stderr)
      @out = out
      @err = err
      @dry_cli = Dry::CLI.new(Commands)
    end

    # Run the CLI with given arguments
    #
    # @param argv [Array<String>] command-line arguments
    # @return [Integer] exit code (0 for success, 1 for error)
    def run(argv)
      @debug = argv.include?("--debug")
      @dry_cli.call(arguments: argv, out: @out, err: @err)
      0
    rescue => e
      handle_error(e)
      1
    end

    attr_reader :out
    attr_reader :err

    # Handle and display errors
    #
    # @param error [Exception] the error to handle
    # @return [void]
    private def handle_error(error) = err.puts(@debug ? error.full_message : error.message)

    # Command registry
    module Commands
      extend Dry::CLI::Registry
    end
  end
end
