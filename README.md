# Wikiwiki

{file:README.ja.md 日本語版}

A Ruby client library and command-line interface for the [Wikiwiki](https://wikiwiki.jp/) REST API.

## Overview

This gem provides both a Ruby library and CLI tool to interact with Wikiwiki wikis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "wikiwiki"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install wikiwiki
```

## Authentication

Before using the API, enable REST API access in your wiki's admin panel.

### Password Authentication

```ruby
auth = Wikiwiki::Auth.password(password: "your_admin_password")
```

### API Key Authentication

```ruby
auth = Wikiwiki::Auth.api_key(api_key_id: "your_api_key_id", secret: "your_secret")
```

### Token Authentication

A JWT token obtained from a previous authentication can be reused within its validity period:

```ruby
auth = Wikiwiki::Auth.token(token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
```

## Usage

### Command Line Interface

The `wikiwiki` command provides access to all API operations:

```bash
# Set credentials via environment variables (optional)
export WIKIWIKI_WIKI_ID=your-wiki-id
export WIKIWIKI_PASSWORD=your-password
# or
export WIKIWIKI_API_KEY_ID=your-api-key-id
export WIKIWIKI_SECRET=your-secret
# or use a pre-obtained token
export WIKIWIKI_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Obtain a token for later use
wikiwiki auth --wiki-id=your-wiki-id --password=your-password
# or combine with export
export WIKIWIKI_TOKEN=$(wikiwiki auth --wiki-id=your-wiki-id --password=your-password)

# List pages
wikiwiki page list

# Show page metadata
wikiwiki page show FrontPage

# Download page content
wikiwiki page get FrontPage
wikiwiki page get FrontPage frontpage.txt

# Upload/update page (from stdin or file)
wikiwiki page put TestPage < content.txt
wikiwiki page put TestPage content.txt

# Delete page
wikiwiki page delete TestPage

# List attachments
wikiwiki attachment list FrontPage

# Show attachment metadata
wikiwiki attachment show FrontPage logo.png

# Download attachment
wikiwiki attachment get FrontPage logo.png
wikiwiki attachment get FrontPage logo.png --directory downloads/

# Upload attachment (max 512 KiB)
wikiwiki attachment put FrontPage image.png
wikiwiki attachment put FrontPage local.png --name remote.png

# Delete attachment
wikiwiki attachment delete FrontPage logo.png

# Use --force to overwrite existing files/attachments
wikiwiki page get FrontPage existing.txt --force
wikiwiki attachment put FrontPage logo.png --force

# Note: Attachment overwrite with --force is not atomic.
# The existing attachment is deleted before uploading the new one.
# If the upload fails, the attachment will be lost.

# Authentication via command line (overrides environment variables)
wikiwiki --wiki-id=your-wiki-id --password=your-password page list
wikiwiki --wiki-id=your-wiki-id --api-key-id=id --secret=secret page list
wikiwiki --wiki-id=your-wiki-id --token=eyJ... page list

# JSON output for automation
wikiwiki page list --json
wikiwiki attachment show FrontPage logo.png --json

# Verbose and debug modes
wikiwiki page list --verbose
wikiwiki page list --debug
```

### Ruby Library

Basic example using the library:

```ruby
require "wikiwiki"

# Initialize with authentication
auth = Wikiwiki::Auth.password(password: "admin_password")
wiki = Wikiwiki::Wiki.new(wiki_id: "your-wiki-id", auth:)

# Obtain and reuse authentication token
token = wiki.token
# Save token for later use...

# Later, use the saved token
auth = Wikiwiki::Auth.token(token: token)
wiki = Wikiwiki::Wiki.new(wiki_id: "your-wiki-id", auth:)

# List all page names
page_names = wiki.page_names
# => ["FrontPage", "SideBar", ...]

# Read a page
page = wiki.page(page_name: "FrontPage")
puts page.source
puts page.timestamp

# Update a page
wiki.update_page(page_name: "TestPage", source: <<~SOURCE)
  TITLE:Test
  # Hello World
SOURCE

# Delete a page
wiki.delete_page(page_name: "TestPage")

# List attachment names
attachment_names = wiki.attachment_names(page_name: "FrontPage")

# Download an attachment
attachment = wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png")
File.binwrite("logo.png", attachment.content)
# Note: If using attachment.name as filename, validate it first to prevent directory traversal attacks

# Upload an attachment
content = File.binread("image.png")
wiki.add_attachment(page_name: "FrontPage", attachment_name: "image.png", content:)

# Delete an attachment
wiki.delete_attachment(page_name: "FrontPage", attachment_name: "image.png")
```

## Reference

- [Page Operations API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/1) (Japanese)
- [File Operations API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/3) (Japanese)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
