# frozen_string_literal: true

require "zeitwerk"
require_relative "wikiwiki/version"

module Wikiwiki
  class Error < StandardError; end

  loader = Zeitwerk::Loader.for_gem
  loader.setup
  loader.eager_load
end
