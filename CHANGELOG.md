## [Unreleased]

### Added

- Pre-obtained token reuse support
  - `Auth.token(token:)` for authentication with pre-obtained JWT tokens
  - `wikiwiki auth` command to obtain authentication tokens
  - `Wiki#token` method to retrieve the current authentication token
  - `--token` option and `WIKIWIKI_TOKEN` environment variable support for all commands
  - JWT token expiration validation with AuthenticationError for expired tokens
- Command-line interface (`wikiwiki` command) for all API operations
  - Page commands: `list`, `show`, `get`, `put`
  - Attachment commands: `list`, `show`, `get`, `put`, `delete`
  - Authentication command: `auth`
  - Environment variable support for credentials (WIKIWIKI_WIKI_ID, WIKIWIKI_TOKEN, WIKIWIKI_PASSWORD, WIKIWIKI_API_KEY_ID, WIKIWIKI_SECRET)
  - JSON output option (`--json`) for automation
  - Verbose (`--verbose`) and debug (`--debug`) modes
  - File overwrite protection with `--force` flag
  - Attachment size limit validation (512 KiB) for uploads

## [0.5.0] - 2025-10-31

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
