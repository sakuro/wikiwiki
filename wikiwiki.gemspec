# frozen_string_literal: true

require_relative "lib/wikiwiki/version"

Gem::Specification.new do |spec|
  spec.name = "wikiwiki"
  spec.version = Wikiwiki::VERSION
  spec.authors = ["OZAWA Sakuro"]
  spec.email = ["10973+sakuro@users.noreply.github.com"]

  spec.summary = "Ruby client library and CLI for Wikiwiki REST API"
  spec.description = <<~DESC
    A Ruby gem providing both a client library and command-line interface for interacting with Wikiwiki.jp REST API.
    Supports page and attachment operations with authentication via password or API key.
  DESC
  spec.homepage = "https://github.com/sakuro/wikiwiki"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) {
    Dir[
      "lib/**/*.rb",
      "exe/*",
      "sig/**/*.rbs",
      "LICENSE",
      "README.md",
      "README.ja.md",
      "CHANGELOG.md"
    ]
  }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "base64", "~> 0.3"
  spec.add_dependency "dry-cli", "~> 1.2"
  spec.add_dependency "jwt", "~> 3.0"
  spec.add_dependency "zeitwerk", "~> 2.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
