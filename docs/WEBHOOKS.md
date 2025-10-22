# Zai Payment Webhook Implementation

## Overview
This document provides a summary of the webhook implementation in the zai_payment gem.

## Architecture

### Core Components

1. **Client** (`lib/zai_payment/client.rb`)
   - Base HTTP client for making API requests
   - Handles authentication automatically via TokenProvider
   - Supports GET, POST, PATCH, DELETE methods
   - Manages connection with proper headers and JSON encoding/decoding

2. **Response** (`lib/zai_payment/response.rb`)
   - Wraps Faraday responses
   - Provides convenient methods: `success?`, `client_error?`, `server_error?`
   - Automatically raises appropriate errors based on HTTP status
   - Extracts data and metadata from response body

3. **Webhook Resource** (`lib/zai_payment/resources/webhook.rb`)
   - Implements all CRUD operations for webhooks
   - Full input validation
   - Clean, documented API

4. **Enhanced Error Handling** (`lib/zai_payment/errors.rb`)
   - Specific error classes for different scenarios
   - Makes debugging and error handling easier

## API Methods

### List Webhooks
```ruby
ZaiPayment.webhooks.list(limit: 10, offset: 0)
```
- Returns paginated list of webhooks
- Response includes `data` (array of webhooks) and `meta` (pagination info)

### Show Webhook
```ruby
ZaiPayment.webhooks.show(webhook_id)
```
- Returns details of a specific webhook
- Raises `NotFoundError` if webhook doesn't exist

### Create Webhook
```ruby
ZaiPayment.webhooks.create(
  url: 'https://example.com/webhook',
  object_type: 'transactions',
  enabled: true,
  description: 'Optional description'
)
```
- Validates URL format
- Validates required fields
- Returns created webhook with ID

### Update Webhook
```ruby
ZaiPayment.webhooks.update(
  webhook_id,
  url: 'https://example.com/new-webhook',
  enabled: false
)
```
- All fields are optional
- Only updates provided fields
- Validates URL format if URL is provided

### Delete Webhook
```ruby
ZaiPayment.webhooks.delete(webhook_id)
```
- Permanently deletes the webhook
- Returns 204 No Content on success

## Error Handling

The gem provides specific error classes:

| Error Class | HTTP Status | Description |
|------------|-------------|-------------|
| `ValidationError` | 400, 422 | Invalid input data |
| `UnauthorizedError` | 401 | Authentication failed |
| `ForbiddenError` | 403 | Access denied |
| `NotFoundError` | 404 | Resource not found |
| `RateLimitError` | 429 | Too many requests |
| `ServerError` | 5xx | Server-side error |
| `TimeoutError` | - | Request timeout |
| `ConnectionError` | - | Connection failed |

Example:
```ruby
begin
  response = ZaiPayment.webhooks.create(...)
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication failed: #{e.message}"
end
```

## Best Practices Implemented

1. **Single Responsibility**: Each class has a clear, focused purpose
2. **DRY (Don't Repeat Yourself)**: Client and Response classes are reusable
3. **Error Handling**: Comprehensive error handling with specific error classes
4. **Input Validation**: All inputs are validated before making API calls
5. **Documentation**: Inline documentation with examples
6. **Testing**: Comprehensive test coverage using RSpec
7. **Thread Safety**: TokenProvider uses mutex for thread-safe token refresh
8. **Configuration**: Centralized configuration management
9. **RESTful Design**: Follows REST principles for resource management
10. **Response Wrapping**: Consistent response format across all methods

## Usage Examples

See `examples/webhooks.rb` for complete examples including:
- Basic CRUD operations
- Pagination
- Error handling
- Custom client instances

## Testing

Run the webhook tests:
```bash
bundle exec rspec spec/zai_payment/resources/webhook_spec.rb
```

The test suite covers:
- All CRUD operations
- Success and error scenarios
- Input validation
- Error handling
- Edge cases

## Future Enhancements

Potential improvements for future versions:
1. Webhook job management (list jobs, show job details)
2. Webhook signature verification
3. Webhook retry logic
4. Bulk operations
5. Async webhook operations

## API Reference

For the official Zai API documentation, see:
- [List Webhooks](https://developer.hellozai.com/reference/getallwebhooks)
- [Show Webhook](https://developer.hellozai.com/reference/getwebhookbyid)
- [Create Webhook](https://developer.hellozai.com/reference/createwebhook)
- [Update Webhook](https://developer.hellozai.com/reference/updatewebhook)
- [Delete Webhook](https://developer.hellozai.com/reference/deletewebhookbyid)

