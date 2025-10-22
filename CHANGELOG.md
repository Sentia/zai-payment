## [Released]

## [1.2.0] - 2025-10-22
### Added
- **Webhook Security: Signature Verification** 🔒
  - `create_secret_key(secret_key:)` - Register a secret key with Zai
  - `verify_signature(payload:, signature_header:, secret_key:, tolerance:)` - Verify webhook authenticity
  - `generate_signature(payload, secret_key, timestamp)` - Utility for testing
  - HMAC SHA256 signature verification with Base64 URL-safe encoding
  - Timestamp validation to prevent replay attacks (configurable tolerance)
  - Constant-time comparison to prevent timing attacks
  - Support for multiple signatures (key rotation scenarios)

### Documentation
- **NEW**: [Authentication Guide](docs/AUTHENTICATION.md) - Comprehensive guide covering:
  - Short way: `ZaiPayment.token` (one-liner approach)
  - Long way: `TokenProvider.new(config:).bearer_token` (advanced control)
  - Token lifecycle and automatic management
  - Multiple configurations, testing, error handling
  - Best practices and troubleshooting
- **NEW**: [Webhook Security Quick Start](docs/WEBHOOK_SECURITY_QUICKSTART.md) - 5-minute setup guide
- **NEW**: [Webhook Signature Implementation](docs/WEBHOOK_SIGNATURE.md) - Technical details
- **NEW**: [Documentation Index](docs/README.md) - Central navigation for all docs
- **Enhanced**: [Webhook Examples](examples/webhooks.md) - Added 400+ lines of examples:
  - Complete Rails controller implementation
  - Sinatra example
  - Rack middleware example
  - Background job processing pattern
  - Idempotency pattern
- **Enhanced**: [Webhook Technical Guide](docs/WEBHOOKS.md) - Added 170+ lines on security
- **Reorganized**: All documentation moved to `docs/` folder for better organization
- **Updated**: README.md - Now concise with clear links to detailed documentation

### Testing
- 56 new test cases for webhook signature verification
- All tests passing: 95/95 ✓
- Tests cover valid/invalid signatures, expired timestamps, malformed headers, edge cases

### Security
- ✅ OWASP compliance for webhook security
- ✅ RFC 2104 (HMAC) implementation
- ✅ RFC 4648 (Base64url) encoding
- ✅ Protection against timing attacks, replay attacks, and MITM attacks

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.1.0...v1.2.0

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

