# frozen_string_literal: true

require "zeitwerk"
require_relative "wikiwiki/version"

# Wikiwiki REST API client library
#
# @example
#   auth = Wikiwiki::Auth.password("admin_password")
#   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
#   page = wiki.page(page_name: "FrontPage")
#   page.name # => "FrontPage"
module Wikiwiki
  # Base error class for Wikiwiki gem
  class Error < StandardError; end

  # Rate limit exceeded error
  class RateLimitError < Error; end

  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect("api" => "API")
  loader.setup
  loader.eager_load
end
