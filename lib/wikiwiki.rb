# frozen_string_literal: true

require "zeitwerk"
require_relative "wikiwiki/version"

# Wikiwiki REST API client library
#
# @example
#   auth = Wikiwiki::Auth.password(password: "admin_password")
#   wiki = Wikiwiki::Wiki.new(wiki_id: "my-wiki", auth:)
#   page = wiki.page(page_name: "FrontPage")
#   page.name # => "FrontPage"
module Wikiwiki
  # Base error class for Wikiwiki gem
  class Error < StandardError; end

  # Rate limit exceeded error
  class RateLimitError < Error; end

  # Content integrity error
  # Raised when downloaded file content doesn't match expected size or MD5 hash
  class ContentIntegrityError < Error; end

  # API request error
  class APIError < Error; end

  # Authentication error
  # Raised when HTTP status is 401
  class AuthenticationError < APIError; end

  # Resource not found error
  # Raised when HTTP status is 404
  class ResourceNotFoundError < APIError; end

  # Server error
  # Raised when HTTP status is 5xx
  class ServerError < APIError; end

  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect("api" => "API")
  loader.setup
  loader.eager_load
end
