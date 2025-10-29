# Wikiwiki

A Ruby client library for the [Wikiwiki](https://wikiwiki.jp/) REST API.

## Overview

This gem provides a simple interface to interact with Wikiwiki wikis programmatically. It supports page operations (read, write, list) and attachment management (upload, download, delete).

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
auth = Wikiwiki::Auth.password("your_admin_password")
```

### API Key Authentication

```ruby
auth = Wikiwiki::Auth.api_key("your_api_key_id", "your_secret")
```

## Usage

### Basic Example

```ruby
require "wikiwiki"

# Initialize with authentication
auth = Wikiwiki::Auth.password("admin_password")
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

# List attachment names
attachment_names = wiki.attachment_names(page_name: "FrontPage")

# Download an attachment
attachment = wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png")
File.binwrite("logo.png", attachment.content)
# Note: If using attachment.name as filename, validate it first to prevent directory traversal attacks

# Upload an attachment
content = File.binread("image.png")
wiki.add_attachment(page_name: "FrontPage", name: "image.png", content:)

# Delete an attachment
wiki.delete_attachment(page_name: "FrontPage", attachment_name: "image.png")
```

## Reference

- [Page Operations API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/1) (Japanese)
- [File Operations API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/3) (Japanese)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
