# frozen_string_literal: true

require "zeitwerk"
require_relative "wikiwiki/version"

# Wikiwiki REST API client library
#
# @example
#   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki")
#   page = wiki.page("FrontPage")
#   page.name # => "FrontPage"
module Wikiwiki
  # Base error class for Wikiwiki gem
  class Error < StandardError; end

  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect("api" => "API")
  loader.setup
  loader.eager_load
end
