## [Released]

## [1.1.0] - 2025-10-22
### Added
- **Webhooks API**: Full CRUD operations for managing Zai webhooks
  - `ZaiPayment.webhooks.list` - List all webhooks with pagination
  - `ZaiPayment.webhooks.show(id)` - Get a specific webhook
  - `ZaiPayment.webhooks.create(...)` - Create a new webhook
  - `ZaiPayment.webhooks.update(id, ...)` - Update an existing webhook
  - `ZaiPayment.webhooks.delete(id)` - Delete a webhook
- **Base API Client**: Reusable HTTP client for all API requests
- **Response Wrapper**: Standardized response handling with error management
- **Enhanced Error Handling**: New error classes for different API scenarios
  - `ValidationError` (400, 422)
  - `UnauthorizedError` (401)
  - `ForbiddenError` (403)
  - `NotFoundError` (404)
  - `RateLimitError` (429)
  - `ServerError` (5xx)
  - `TimeoutError` and `ConnectionError` for network issues
- Comprehensive test suite for webhook functionality
- Example code in `examples/webhooks.rb`

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.0.2...v1.1.0

## [1.0.2] - 2025-10-22
- Update gemspec files and readme

**Full Changelog**: https://github.com/Sentia/zai-payment/releases/tag/v1.0.2


##[1.0.1] - 2025-10-21
- Update readme and versions

**Full Changelog**: https://github.com/Sentia/zai-payment/releases/tag/v1.0.1


## [1.0.0] - 2025-10-21

- Initial release: token auth client with in-memory caching (`ZaiPayment.token`, `refresh_token!`, `clear_token!`, `token_type`, `token_expiry`)

**Full Changelog**: https://github.com/Sentia/zai-payment/commits/v1.0.0

