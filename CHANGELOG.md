## [Unreleased]

### Added

- Initial release of Wikiwiki REST API client library
- Support for password and API key authentication
- Page operations: list, read, and update
- Attachment operations: list, download, upload, and delete
- Automatic rate limiting with configurable strategies (raise, wait, or no limit)
- Full RBS type signatures for type safety
- `Wiki#url` method to get the wiki URL as a frozen `URI::HTTPS` instance
