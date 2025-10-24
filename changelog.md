## [Released]

## [2.0.0] - 2025-10-24
### Added
- **Items Management API**: Full CRUD operations for managing Zai items (transactions/payments) 🛒
  - `ZaiPayment.items.list(limit:, offset:)` - List all items with pagination
  - `ZaiPayment.items.show(item_id)` - Get item details by ID
  - `ZaiPayment.items.create(**attributes)` - Create new item/transaction
  - `ZaiPayment.items.update(item_id, **attributes)` - Update item information
  - `ZaiPayment.items.delete(item_id)` - Delete an item
  - `ZaiPayment.items.show_seller(item_id)` - Get seller details for an item
  - `ZaiPayment.items.show_buyer(item_id)` - Get buyer details for an item
  - `ZaiPayment.items.show_fees(item_id)` - Get fees associated with an item
  - `ZaiPayment.items.show_wire_details(item_id)` - Get wire transfer details for an item
  - `ZaiPayment.items.list_transactions(item_id, limit:, offset:)` - List transactions for an item
  - `ZaiPayment.items.list_batch_transactions(item_id, limit:, offset:)` - List batch transactions for an item
  - `ZaiPayment.items.show_status(item_id)` - Get current status of an item
- Comprehensive validation for item attributes (name, amount, payment_type, buyer_id, seller_id)
- Support for optional item fields (description, currency, fee_ids, custom_descriptor, deposit_reference, etc.)
- Full RSpec test suite for Items resource with 100% coverage
- Comprehensive examples documentation in `examples/items.md`

### Documentation
- Added detailed Items API examples with complete workflow demonstrations
- Payment types documentation (1-7: Direct Debit, Credit Card, Bank Transfer, Wallet, BPay, PayPal, Other)
- Error handling examples for Items operations

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.3.2...v2.0.0

## [1.3.2] - 2025-10-23
### Added
- YARD documentation generation support with `.yardopts` configuration
- Added `yard` gem as development dependency for API documentation

### Fixed
- Fixed YARD link resolution warning in README.md by converting markdown link to HTML format

### Documentation
- Configured YARD to generate comprehensive API documentation
- Documentation coverage: 70.59% (51 methods, 22 classes, 5 modules)

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.3.1...v1.3.2

## [1.3.1] - 2025-10-23
### Changed
- Update error response format
- Update some docs

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.3.0...v1.3.1

## [1.3.0] - 2025-10-23
### Added
- **User Management API**: Full CRUD operations for managing Zai users (payin and payout) 👥
  - `ZaiPayment.users.list(limit:, offset:)` - List all users with pagination
  - `ZaiPayment.users.show(user_id)` - Get user details by ID
  - `ZaiPayment.users.create(**attributes)` - Create payin (buyer) or payout (seller/merchant) users
  - `ZaiPayment.users.update(user_id, **attributes)` - Update user information
  - Support for both payin users (buyers) and payout users (sellers/merchants)
  - Comprehensive validation for all user types
  - Email format validation
  - Country code validation (ISO 3166-1 alpha-3)
  - Date of birth format validation (DD/MM/YYYY)
  - User type validation (payin/payout)
  - Progressive profile building support

### Enhancements
- **Client**: Added `base_endpoint` parameter to support multiple API endpoints
  - Users API uses `core_base` endpoint
  - Webhooks API continues to use `va_base` endpoint
- **Response**: Updated `data` method to handle both `webhooks` and `users` response formats
- **Main Module**: Added `users` accessor for convenient access to User resource

### Documentation
- **NEW**: [User Management Guide](docs/users.md) - Comprehensive guide covering:
  - Overview of payin vs payout users
  - Required fields for each user type
  - Complete API reference with examples
  - Field reference table
  - Error handling patterns
  - Best practices for each user type
  - Response structures
- **NEW**: [User Examples](examples/users.md) - 500+ lines of practical examples:
  - Basic and advanced payin user creation
  - Progressive profile building patterns
  - Payout user creation (individual and company)
  - International users (AU, UK, US)
  - List, search, and pagination
  - Update operations
  - Rails integration examples
  - Batch operations
  - User profile validation helper
  - RSpec integration tests
  - Common patterns with retry logic
- **NEW**: [User Quick Reference](docs/user_quick_reference.md) - Quick lookup for common operations
- **NEW**: [User Demo Script](examples/user_demo.rb) - Interactive demo of all user operations
- **NEW**: [Implementation Summary](implementation.md) - Detailed summary of the implementation
- **Updated**: readme.md - Added Users section with quick examples and updated roadmap

### Testing
- 40+ new test cases for User resource
- All CRUD operations tested
- Validation error handling tested
- API error handling tested
- Integration tests with main module
- Tests for both payin and payout user types

### API Endpoints
- `GET /users` - List users
- `GET /users/:id` - Show user
- `POST /users` - Create user
- `PATCH /users/:id` - Update user

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.2.0...v1.3.0

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
- **NEW**: [Authentication Guide](docs/authentication.md) - Comprehensive guide covering:
  - Short way: `ZaiPayment.token` (one-liner approach)
  - Long way: `TokenProvider.new(config:).bearer_token` (advanced control)
  - Token lifecycle and automatic management
  - Multiple configurations, testing, error handling
  - Best practices and troubleshooting
- **NEW**: [Webhook Security Quick Start](docs/webhook_security_quickstart.md) - 5-minute setup guide
- **NEW**: [Webhook Signature Implementation](docs/webhook_signature.md) - Technical details
- **NEW**: [Documentation Index](docs/readme.md) - Central navigation for all docs
- **Enhanced**: [Webhook Examples](examples/webhooks.md) - Added 400+ lines of examples:
  - Complete Rails controller implementation
  - Sinatra example
  - Rack middleware example
  - Background job processing pattern
  - Idempotency pattern
- **Enhanced**: [Webhook Technical Guide](docs/webhooks.md) - Added 170+ lines on security
- **Reorganized**: All documentation moved to `docs/` folder for better organization
- **Updated**: readme.md - Now concise with clear links to detailed documentation

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

