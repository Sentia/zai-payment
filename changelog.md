## [Released]

## [2.8.3] - 2025-11-21

### Added
- **Wallet Account Withdraw**: New withdraw method for Wallet Account resource 💰
  - `ZaiPayment.wallet_accounts.withdraw(wallet_account_id, account_id:, amount:, **options)` - Withdraw funds from a wallet account to a disbursement account
  - Support for basic withdrawals with account_id and amount
  - Support for custom descriptors (max 200 chars for NPP, 18 for DE batch)
  - Support for reference IDs (cannot contain '.' character)
  - Support for NPP IFTI payouts with end_to_end_id and ifti_information
  - Validation for required fields (account_id, amount)
  - Validation for custom descriptor length
  - Validation for reference_id format
  - Comprehensive YARD documentation with examples

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.8.2...v2.8.3

## [2.8.1] - 2025-11-07

### Fixed
- **Response Data Extraction Bug**: Fixed `.data` method returning only `routing_number` value instead of full object 🐛
  - Removed `routing_number` from `RESPONSE_DATA_KEYS` constant - it's a field within responses, not a collection wrapper key
  - The `.data` method was incorrectly treating `routing_number` as a top-level data key
  - This caused `response.data` to return just `"803320"` (the routing number) instead of the complete virtual account object
  - Now properly returns the full response object when no wrapper key is found
  - Affected resources: Virtual Accounts (and potentially other resources with `routing_number` field)
  - Updated test mocks to match actual API response format (flat objects for single resources)
  
### Changed
- **Virtual Account Test Fixtures**: Updated response structure to match actual Zai API format
  - Single resource responses (show, create, update) now return flat objects without wrapper keys
  - Collection responses (list) continue to use `virtual_accounts` wrapper key
  - All 87 virtual account tests passing with corrected response structure

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.8.0...v2.8.1

## [2.8.0] - 2025-11-07

### Added
- **Virtual Accounts Resource**: Complete virtual account management for Australian payments 🏦
  - `ZaiPayment.virtual_accounts.list(wallet_account_id)` - List all virtual accounts for a wallet account
  - `ZaiPayment.virtual_accounts.show(virtual_account_id)` - Get virtual account details
  - `ZaiPayment.virtual_accounts.create(wallet_account_id, account_name:, aka_names:)` - Create virtual account for a wallet account
  - `ZaiPayment.virtual_accounts.update_aka_names(virtual_account_id, aka_names)` - Update AKA names (0-3 items)
  - `ZaiPayment.virtual_accounts.update_account_name(virtual_account_id, account_name)` - Update account name (used in CoP lookups)
  - `ZaiPayment.virtual_accounts.update_status(virtual_account_id, status)` - Close a virtual account (status: 'closed')
  - Support for AKA names for account aliases
  - Support for Confirmation of Payee (CoP) lookups via account names
  - Validation for account names (max 140 characters)
  - Validation for AKA names (0-3 items)
  - Full RSpec test suite with 65+ test examples
  - Comprehensive documentation in `docs/virtual_accounts.md`
  - Practical examples in `examples/virtual_accounts.md`

- **PayID Resource**: PayID registration management for Australian NPP payments 💳
  - `ZaiPayment.pay_ids.create(virtual_account_id, pay_id:, type:, details:)` - Register a PayID for a virtual account
  - `ZaiPayment.pay_ids.show(pay_id_id)` - Get PayID details including status
  - `ZaiPayment.pay_ids.update_status(pay_id_id, status)` - Deregister a PayID (status: 'deregistered')
  - Support for EMAIL PayID type
  - Validation for PayID format (max 256 characters)
  - Validation for details (pay_id_name and owner_legal_name, 1-140 characters each)
  - Asynchronous status update with 202 Accepted response
  - Full RSpec test suite with 35+ test examples
  - Comprehensive documentation in `docs/pay_ids.md`
  - Practical examples in `examples/pay_ids.md`

### Documentation
- **Virtual Accounts Guide** (`docs/virtual_accounts.md`):
  - Complete guide for all 6 virtual account endpoints
  - Detailed workflow for account creation and management
  - AKA names for account aliases
  - Account name updates for CoP lookups
  - Status updates for closing accounts
  - Error handling patterns
  - Comprehensive use cases

- **Virtual Accounts Examples** (`examples/virtual_accounts.md`):
  - List virtual accounts examples
  - Show virtual account examples
  - Create virtual account examples
  - Update AKA names examples
  - Update account name examples
  - Update status (close account) examples
  - Complete workflow patterns
  - Rails integration examples

- **PayID Guide** (`docs/pay_ids.md`):
  - Complete guide for all 3 PayID endpoints
  - PayID registration with EMAIL type
  - PayID format validation rules
  - Status updates for deregistration
  - Integration with virtual accounts
  - Error handling patterns
  - Comprehensive use cases

- **PayID Examples** (`examples/pay_ids.md`):
  - Register PayID examples
  - Show PayID examples
  - Update status (deregister) examples
  - Complete workflow patterns
  - Rails integration examples

### Enhanced
- **README.md**: 
  - Added Virtual Accounts to features section
  - Added PayID to features section
  - Added documentation links to virtual accounts and PayID guides
  - Updated roadmap to mark Virtual Accounts and PayID as Done

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.7.0...v2.8.0

## [2.7.0] - 2025-11-04

### Added
- **Batch Transactions Resource**: Complete batch transaction management for testing in prelive environment 🔄
  - `ZaiPayment.batch_transactions.export_transactions` - Export pending transactions to batched state
  - `ZaiPayment.batch_transactions.process_to_bank_processing(batch_id, exported_ids:)` - Move batch to bank_processing state
  - `ZaiPayment.batch_transactions.process_to_successful(batch_id, exported_ids:)` - Complete batch processing (triggers webhooks)
  - `ZaiPayment.batch_transactions.show_batches` - List all batches
  - `ZaiPayment.batch_transactions.show_batch(batch_id)` - Get specific batch details
  - `ZaiPayment.batch_transactions.show_transactions(batch_id, limit:, offset:)` - List transactions in a batch with pagination
  - Prelive-only endpoints for testing transaction processing workflows
  - Full RSpec test suite with 20+ test examples
  - Comprehensive documentation in `docs/batch_transactions.md`
  - Practical examples in `examples/batch_transactions.md`

- **Wallet Account Resource**: Complete wallet account management for Australian payments 💼
  - `ZaiPayment.wallet_accounts.show(wallet_account_id)` - Get wallet account details including balance
  - `ZaiPayment.wallet_accounts.show_user(wallet_account_id)` - Get user associated with wallet account
  - `ZaiPayment.wallet_accounts.show_npp_details(wallet_account_id)` - Get NPP (New Payments Platform) details including PayID
  - `ZaiPayment.wallet_accounts.show_bpay_details(wallet_account_id)` - Get BPay details including biller code and reference
  - `ZaiPayment.wallet_accounts.pay_bill(wallet_account_id, account_id:, amount:, reference_id:)` - Pay bills via BPay from wallet
  - Support for checking wallet balances before transactions
  - Support for NPP payments with PayID
  - Support for BPay bill payments
  - Validation for payment amounts and reference IDs
  - Full RSpec test suite with 35+ test examples across 5 describe blocks
  - Comprehensive documentation in `docs/wallet_accounts.md`
  - Practical examples in `examples/wallet_accounts.md`

### Documentation
- **Batch Transactions Guide** (`docs/batch_transactions.md`):
  - Complete guide for all 6 batch transaction endpoints
  - Detailed workflow for simulating batch processing
  - State transition diagrams and examples
  - Error handling patterns for batch operations
  - Important notes about prelive-only usage
  
- **Batch Transactions Examples** (`examples/batch_transactions.md`):
  - Export transactions examples (3 examples)
  - Process to bank_processing examples (3 examples)
  - Process to successful examples (3 examples)
  - Show batches and transactions examples (6 examples)
  - Complete workflow patterns
  - Rails integration examples
  - Webhook simulation workflows

- **Wallet Accounts Guide** (`docs/wallet_accounts.md`):
  - Complete guide for all 5 wallet account endpoints
  - Balance checking and payment workflows
  - NPP PayID integration examples
  - BPay bill payment patterns
  - Validation rules and error handling
  - Four comprehensive use cases:
    - Balance verification before payment
    - Multiple bill payments workflow
    - User verification for payments
    - Disbursement status monitoring

- **Wallet Accounts Examples** (`examples/wallet_accounts.md`):
  - Show wallet account examples (3 examples)
  - Show user examples (3 examples)
  - NPP details examples
  - BPay details examples
  - Pay bill examples (3 examples)
  - Three common patterns:
    - Complete payment workflow
    - Wallet payment service class
    - Rails controller integration

### Enhanced
- **Response Class**: Added `disbursements` to `RESPONSE_DATA_KEYS` for automatic data extraction
  - `response.data` now properly extracts disbursement objects from pay_bill responses
  - Consistent with other resource response handling

### Updated
- **README.md**: 
  - Added Wallet Accounts to features section
  - Added Batch Transactions documentation links
  - Updated roadmap to mark Payments as Done
  - Added quick start examples for wallet account operations

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.6.1...v2.7.0

## [2.6.1] - 2025-11-03

### Changed
- **Wallet Accounts Response Structure**: Updated to match actual API response format 🔄
  - Response now properly returns nested `wallet_accounts` object with complete structure
  - Added `wallet_accounts` to `Response#data` automatic extraction
  - The `Response#data` method now automatically extracts the `wallet_accounts` object for cleaner API usage
  - Updated response includes: `id`, `active`, `created_at`, `updated_at`, `balance`, `currency`
  - Enhanced `links` structure with: `self`, `users`, `batch_transactions`, `transactions`, `bpay_details`, `npp_details`, `virtual_accounts`

### Improved
- **API Consistency**: `response.data` now works consistently across all resources
  - Before: `response.data['wallet_accounts']['balance']` (manual extraction)
  - After: `response.data['balance']` (automatic extraction)
- **Documentation**: Updated all wallet_account documentation and examples
  - Updated `docs/users.md` with complete wallet account response structure
  - Added note about automatic data extraction in Response class
  - Updated code examples in `lib/zai_payment/resources/user.rb`
- **Test Coverage**: Enhanced wallet_account test suite
  - Split tests into focused examples for better maintainability
  - Added comprehensive validation for all wallet account fields
  - Tests for active status, timestamps, and all link fields
  - All tests comply with RuboCop standards

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.6.0...v2.6.1

## [2.6.0] - 2025-11-03

### Added
- **BPay Account Resource**: Complete BPay account management for Australian bill payments 💰
  - `ZaiPayment.bpay_accounts.show(bpay_account_id)` - Get BPay account details including biller information
  - `ZaiPayment.bpay_accounts.create(user_id:, account_name:, biller_code:, bpay_crn:)` - Create BPay account for disbursement destinations
  - `ZaiPayment.bpay_accounts.redact(bpay_account_id)` - Redact (deactivate) a BPay account
  - `ZaiPayment.bpay_accounts.show_user(bpay_account_id)` - Get user associated with a BPay account
  - Validation for biller code (3-10 digits)
  - Validation for BPay CRN (Customer Reference Number, 2-20 digits)
  - Support for Australian bill payment disbursements
  - Full RSpec test suite with 12 test examples across 4 describe blocks
  - Comprehensive documentation in `docs/bpay_accounts.md`
  - Practical examples in `examples/bpay_accounts.md`

### Documentation
- **BPay Accounts Guide** (`docs/bpay_accounts.md`):
  - Complete guide for showing, creating, redacting BPay accounts, and retrieving associated users
  - Detailed API reference for all four endpoints
  - Response structure documentation with example payloads
  - Validation rules for biller codes and BPay CRN formats
  - Error handling documentation (ValidationError, NotFoundError)
  - Four comprehensive use cases:
    - Disbursement account setup for bill payments
    - User verification before disbursement
    - Deactivating old BPay accounts
    - Managing multiple utility BPay accounts
  - Important notes about BPay account usage and restrictions
- **BPay Accounts Examples** (`examples/bpay_accounts.md`):
  - Show BPay account examples (3 examples):
    - Basic account retrieval with full details
    - Error handling and status verification
    - Pre-disbursement verification workflow
  - Show BPay account user examples (3 examples):
    - User information retrieval
    - User verification before disbursement
    - Contact information extraction for notifications
  - Redact BPay account examples (3 examples):
    - Basic redaction with response handling
    - Comprehensive error handling
    - Verification before redacting workflow
  - Create BPay account examples (3 examples):
    - Basic account creation
    - Error handling patterns
    - Multiple utility account setup
  - Four common patterns:
    - Retrieve and verify before disbursement
    - Complete onboarding workflow with user creation
    - BPay account form handler for Rails applications
    - BPay details validation helper

### Features
- BPay accounts work as disbursement destinations for Australian bill payments
- Supports all major Australian billers (utilities, telecommunications, financial services, government)
- Automatic biller name lookup based on biller code
- Full lifecycle management (create, show, show_user, redact)
- Secure validation of BPay-specific formats

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.5.0...v2.6.0

## [2.5.0] - 2025-11-03

### Added
- **Bank Account Resource**: Complete CRUD operations plus validation for Australian and UK bank accounts 🏦
  - `ZaiPayment.bank_accounts.show(bank_account_id, include_decrypted_fields:)` - Get bank account details with optional decrypted fields
  - `ZaiPayment.bank_accounts.create_au(user_id:, bank_name:, account_name:, routing_number:, account_number:, account_type:, holder_type:, country:)` - Create Australian bank account
  - `ZaiPayment.bank_accounts.create_uk(user_id:, bank_name:, account_name:, routing_number:, account_number:, account_type:, holder_type:, country:, iban:, swift_code:)` - Create UK bank account with IBAN and SWIFT code
  - `ZaiPayment.bank_accounts.redact(bank_account_id)` - Redact (deactivate) a bank account
  - `ZaiPayment.bank_accounts.validate_routing_number(routing_number)` - Validate US bank routing numbers and get bank information
  - Support for retrieving decrypted sensitive fields (full account numbers)
  - Support for savings and checking account types
  - Support for personal and business holder types
  - Comprehensive validation for required fields and formats
  - Full RSpec test suite with 25 test examples
  - Comprehensive documentation in `docs/bank_accounts.md`
  - Practical examples in `examples/bank_accounts.md`

### Documentation
- **Bank Accounts Guide** (`docs/bank_accounts.md`):
  - Complete guide for showing, creating, validating, and redacting bank accounts
  - Documentation for decrypted fields parameter
  - Validation endpoint documentation for US routing numbers
  - Redaction endpoint documentation with warnings
  - Validation rules for account types, holder types, and country codes
  - Response structure documentation
  - Error handling examples
  - Use cases for disbursement accounts, multi-currency setups, and routing number validation
- **Bank Accounts Examples** (`examples/bank_accounts.md`):
  - Examples for retrieving bank account details (masked and decrypted)
  - Examples for redacting bank accounts with error handling (Examples 9-10)
  - Examples for validating US routing numbers (Examples 11-13)
  - Real-world scenarios for Australian bank accounts
  - UK bank account creation with IBAN/SWIFT
  - Business account setup examples
  - Multi-region account management patterns
  - Routing number validation integration in forms
  - Security best practices for handling decrypted data

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.4.0...v2.5.0

## [2.4.0] - 2025-11-02
### Added
- **Item Payment Actions API**: Advanced payment operations for managing item transactions 💳
  - `ZaiPayment.items.make_payment(item_id, account_id:, device_id:, ip_address:, cvv:, merchant_phone:)` - Process a payment for an item
  - `ZaiPayment.items.cancel(item_id)` - Cancel an item/transaction
  - `ZaiPayment.items.refund(item_id, refund_amount:, refund_message:, account_id:)` - Refund a payment
  - `ZaiPayment.items.authorize_payment(item_id, account_id:, cvv:, merchant_phone:)` - Authorize a payment without capturing
  - `ZaiPayment.items.capture_payment(item_id, amount:)` - Capture a previously authorized payment
  - `ZaiPayment.items.void_payment(item_id)` - Void an authorized payment
  - `ZaiPayment.items.make_payment_async(item_id, account_id:, request_three_d_secure:)` - Process an async payment with 3D Secure 2.0 support
- Support for pre-authorization workflows (authorize then capture)
- Support for async payment methods (direct debit, bank transfers, PayPal)
- Comprehensive validation for payment parameters
- Full RSpec test suite for all payment actions
- Comprehensive documentation in `docs/items.md` and `examples/items.md`

### Documentation
- **Updated Items Guide** (`docs/items.md`):
  - Complete payment workflow examples
  - Pre-authorization and capture patterns
  - Refund and cancellation examples
  - Async payment handling
  - Error handling for payment operations
- **Updated Items Examples** (`examples/items.md`):
  - Real-world payment scenarios
  - Card payment workflows
  - Direct debit examples
  - PayPal integration patterns
  - Refund and dispute handling

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.3.2...v2.4.0

## [2.3.2] - 2025-10-29
### Fixed
- **Timeout Error Handling**: Improved handling of timeout errors to prevent crashes
  - Added explicit rescue for `Net::ReadTimeout` and `Net::OpenTimeout` errors
  - Previously, these errors could sometimes bypass Faraday's error handling and crash the application
  - Now properly converts all timeout errors to `Errors::TimeoutError` with descriptive messages
  - Fixes issue: "Request timed out: Net::ReadTimeout with #<TCPSocket:(closed)>"
  
### Changed
- **Increased Default Timeouts**: Adjusted default timeout values for better reliability
  - Default `timeout` increased from 10 to 30 seconds (general request timeout)
  - Added separate `read_timeout` configuration (default: 30 seconds)
  - `open_timeout` remains at 10 seconds (connection establishment)
  - Users can still customize timeouts via configuration:
    ```ruby
    ZaiPayment.configure do |config|
      config.timeout = 60        # Custom general timeout
      config.read_timeout = 60   # Custom read timeout
      config.open_timeout = 15   # Custom open timeout
    end
    ```

## [2.3.1] - 2025-10-28
### Fixed
- **Token Refresh Bug**: Fixed authentication token not being refreshed after expiration
  - Previously, the Authorization header was set once when the connection was created
  - After ~1 hour, tokens would expire and subsequent API calls would fail with `UnauthorizedError`
  - Now, the Authorization header is set dynamically on each request, ensuring fresh tokens are always used
  - The `TokenProvider` automatically refreshes expired tokens, preventing authentication errors
  - Fixes issue where some APIs would work while others failed after token expiration

## [2.3.0] - 2025-10-28
### Added
- **User Management API Enhancement**: Added search parameter to list users endpoint
  - `ZaiPayment.users.list(limit:, offset:, search:)` - Search users by text value
  - Search parameter is optional and filters users by email, name, or other text fields
  - Example: `users.list(search: "john@example.com")`

### Changed
- Coverage badge updated to 97.15%

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.2.0...v2.3.0

## [2.2.0] - 2025-10-24
### Added
- **Extended User Management API**: 7 new user-related endpoints 🚀
  - `ZaiPayment.users.wallet_account(user_id)` - Show user's wallet account details
  - `ZaiPayment.users.items(user_id, limit:, offset:)` - List items associated with user (paginated)
  - `ZaiPayment.users.set_disbursement_account(user_id, account_id)` - Set user's disbursement account
  - `ZaiPayment.users.bank_account(user_id)` - Show user's active bank account
  - `ZaiPayment.users.verify(user_id)` - Verify user (prelive environment only)
  - `ZaiPayment.users.card_account(user_id)` - Show user's active card account
  - `ZaiPayment.users.bpay_accounts(user_id)` - List user's BPay accounts
- All endpoints include comprehensive nested data structures:
  - Bank accounts with nested `bank` details (account_name, routing_number, account_type, holder_type)
  - Card accounts with nested `card` details (type, full_name, masked number, expiry)
  - BPay accounts with nested `bpay_details` (biller_code, biller_name, CRN, account_name)
  - Items with full transaction details (buyer/seller info, payment_type, status, links to related resources)
- Validation for all user_id and account_id parameters
- Links to related resources included in all responses

### Enhanced
- **Response Class Refactoring**: Improved data extraction logic
  - Replaced complex conditional chain with iterative approach using `RESPONSE_DATA_KEYS` constant
  - Added support for new data keys: `bpay_accounts`, `bank_accounts`, `card_accounts`
  - Reduced complexity metrics (ABC, Cyclomatic, Perceived Complexity)
  - More maintainable and extensible architecture
- **User Creation Validation**: Made `user_type` a required field
  - Added validation to ensure `user_type` ('payin' or 'payout') is specified when creating users
  - Improved error messages for missing required fields
  - Enhanced test suite with compact, readable validation tests

### Documentation
- **Updated User Management Guide** (`docs/users.md`):
  - Comprehensive examples for all 7 new endpoints
  - Complete response structures with real API data
  - Detailed field access patterns for nested objects
  - Pagination examples for list endpoints
  - Related resource link usage examples
- **Updated README.md**:
  - Added quick reference for all new endpoints
  - Updated user management section with complete API surface
- Real API response examples integrated for:
  - List User Items (with buyer/seller details, transaction links)
  - List User's BPay Accounts (with biller details, verification status)
  - Show User Bank Account (with bank details, direct debit authorities)
  - Show User Card Account (with card details, CVV verification status)

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.1.0...v2.2.0

## [2.1.0] - 2025-10-24
### Added
- **Token Auth API**: Token generation for bank and card accounts 🔐
  - `ZaiPayment.token_auths.generate(user_id:, token_type:)` - Generate tokens for secure payment data collection
  - Support for bank tokens (collecting bank account information)
  - Support for card tokens (collecting credit card information)
  - Token type validation (bank or card)
  - User ID validation
  - Full RSpec test suite for TokenAuth resource
  - Comprehensive examples documentation in `examples/token_auths.md`

### Documentation
- Added detailed TokenAuth API examples with complete integration patterns
- Frontend integration examples (PromisePay.js)
- Rails controller integration examples
- Service object pattern examples
- Error handling and retry logic examples
- Security best practices (token expiry management, audit logging, rate limiting)
- Complete payment flow example

### Testing
- 20+ new test cases for TokenAuth resource
- Validation error handling tested
- Case-insensitive token type support tested
- Default parameter behavior tested

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v2.0.2...v2.1.0

## [2.0.2] - 2025-10-24
### Fixed
- **Items API**: Fixed endpoint configuration to use `core_base` instead of `va_base`
  - Items resource now correctly uses the `https://test.api.promisepay.com` endpoint (prelive) 
  - Resolves CloudFront 403 error when creating items via POST requests
  - Ensures Items API uses the same endpoint as Users API for consistency

## [2.0.1] - 2025-10-24
### Changes
  - Updated markdown files

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

### Changed
- **User Management Enhancement**: Updated user creation validation to support user type-specific required fields
  - `user_type` parameter now determines which fields are required during user creation
  - Payin users require: `email`, `first_name`, `last_name`, `country`
  - Payout users require additional fields: `address_line1`, `city`, `state`, `zip`, `dob`
  - Company validation now enforces required fields based on user type
  - For payout companies, additional fields required: `address_line1`, `city`, `state`, `zip`, `phone`, `country`
  - All companies require: `name`, `legal_name`, `tax_number`, `business_email`, `country`
- **Clarified device_id and ip_address requirements**: These fields are NOT required when creating a payin user, but become required when creating an item and charging a card
- Refactored company validation logic for better maintainability and reduced cyclomatic complexity

### Documentation
- Added detailed Items API examples with complete workflow demonstrations
- Payment types documentation (1-7: Direct Debit, Credit Card, Bank Transfer, Wallet, BPay, PayPal, Other)
- Error handling examples for Items operations
- Updated User Management documentation (`docs/users.md`) with correct required fields for each user type
- Updated all user examples in `examples/users.md` to reflect proper user type usage
- Added clear notes about when `device_id` and `ip_address` are required
- Updated company field requirements in all documentation

**Full Changelog**: https://github.com/Sentia/zai-payment/compare/v1.3.2...v2.0.0

## [1.3.2] - 2025-10-23
### Added
- YARD documentation generation support with `.yardopts` configuration
- Added `yard` gem as development dependency for API documentation

### Fixed
- Fixed YARD link resolution warning in readme.md by converting markdown link to HTML format

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

