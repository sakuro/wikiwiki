## [Unreleased]

### Added

- Initial release of Wikiwiki REST API client library
- Support for password and API key authentication
- Page operations: list, read, and update
- Attachment operations: list, download, upload, and delete
- Automatic rate limiting with configurable strategies (raise, wait, or no limit)
- Full RBS type signatures for type safety
- `Wiki#url` method to get the wiki URL as a frozen `URI::HTTPS` instance
- Logging support for API requests and responses with configurable logger (default: Logger.new($stdout))
  - Request/response URLs and status codes logged at INFO level
  - HTTP headers logged at DEBUG level (with Authorization masked as "Bearer ***")
  - Each log entry is prefixed with `[wiki-id]` for easy filtering
  - Logger accessible via `Wiki#logger` and `API#logger` reader methods
