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
2. ~~Webhook signature verification~~ ✅ **Implemented**
3. Webhook retry logic
4. Bulk operations
5. Async webhook operations

## Webhook Security: Signature Verification

### Overview

Webhook signature verification ensures that webhook requests truly come from Zai and haven't been tampered with. This protection guards against:
- **Man-in-the-middle attacks**: Verify the sender is Zai
- **Replay attacks**: Timestamp verification prevents old webhooks from being reused
- **Data tampering**: HMAC ensures the payload hasn't been modified

### Setup

#### Step 1: Generate and Store a Secret Key

First, create a secret key that will be shared between you and Zai:

```ruby
require 'securerandom'

# Generate a cryptographically secure secret key (at least 32 bytes)
secret_key = SecureRandom.alphanumeric(32)

# Store this securely in your environment variables
# DO NOT commit this to version control!
ENV['ZAI_WEBHOOK_SECRET'] = secret_key

# Register the secret key with Zai
response = ZaiPayment.webhooks.create_secret_key(secret_key: secret_key)

if response.success?
  puts "Secret key registered successfully!"
end
```

**Important Security Notes:**
- Store the secret key in environment variables or a secure vault (e.g., AWS Secrets Manager, HashiCorp Vault)
- Never commit the secret key to version control
- Rotate the secret key periodically
- Use at least 32 bytes for the secret key

#### Step 2: Verify Webhook Signatures

In your webhook endpoint, verify each incoming request:

```ruby
# Rails example
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def zai_webhook
    payload = request.body.read
    signature_header = request.headers['Webhooks-signature']
    secret_key = ENV['ZAI_WEBHOOK_SECRET']

    begin
      # Verify the signature
      if ZaiPayment.webhooks.verify_signature(
        payload: payload,
        signature_header: signature_header,
        secret_key: secret_key,
        tolerance: 300 # 5 minutes
      )
        # Signature is valid, process the webhook
        webhook_data = JSON.parse(payload)
        process_webhook(webhook_data)
        
        render json: { status: 'success' }, status: :ok
      else
        # Invalid signature
        render json: { error: 'Invalid signature' }, status: :unauthorized
      end
    rescue ZaiPayment::Errors::ValidationError => e
      # Signature verification failed (e.g., timestamp too old)
      Rails.logger.error "Webhook signature verification failed: #{e.message}"
      render json: { error: e.message }, status: :unauthorized
    end
  end

  private

  def process_webhook(data)
    # Your webhook processing logic here
    Rails.logger.info "Processing webhook: #{data['event']}"
  end
end
```

### How It Works

The verification process follows these steps:

1. **Extract Components**: Parse the `Webhooks-signature` header to get timestamp and signature(s)
   - Header format: `t=1257894000,v=signature1,v=signature2`

2. **Verify Timestamp**: Check that the webhook isn't too old (prevents replay attacks)
   - Default tolerance: 300 seconds (5 minutes)
   - Configurable via the `tolerance` parameter

3. **Generate Expected Signature**: Create HMAC SHA256 signature
   - Signed payload: `timestamp.request_body`
   - Uses base64url encoding (URL-safe, no padding)

4. **Compare Signatures**: Use constant-time comparison to prevent timing attacks
   - Returns `true` if any signature in the header matches

### Advanced Examples

#### Custom Tolerance Window

```ruby
# Allow webhooks up to 10 minutes old
ZaiPayment.webhooks.verify_signature(
  payload: payload,
  signature_header: signature_header,
  secret_key: secret_key,
  tolerance: 600 # 10 minutes
)
```

#### Generate Signatures for Testing

```ruby
# Generate a signature for testing your webhook endpoint
payload = '{"event": "transaction.updated", "id": "txn_123"}'
secret_key = ENV['ZAI_WEBHOOK_SECRET']
timestamp = Time.now.to_i

signature = ZaiPayment.webhooks.generate_signature(payload, secret_key, timestamp)
signature_header = "t=#{timestamp},v=#{signature}"

# Now use this in your test request
# This is useful for integration tests
```

#### Handling Multiple Signatures

Zai may include multiple signatures in the header (e.g., during key rotation):

```ruby
# The verify_signature method automatically handles multiple signatures
# It returns true if ANY signature matches
signature_header = "t=1257894000,v=old_sig,v=new_sig"
result = ZaiPayment.webhooks.verify_signature(
  payload: payload,
  signature_header: signature_header,
  secret_key: secret_key
)
```

### Testing Your Implementation

Create a test to ensure your webhook endpoint properly validates signatures:

```ruby
require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do
  let(:secret_key) { SecureRandom.alphanumeric(32) }
  let(:payload) { { event: 'transaction.updated', id: 'txn_123' }.to_json }
  let(:timestamp) { Time.now.to_i }
  
  before do
    ENV['ZAI_WEBHOOK_SECRET'] = secret_key
  end

  describe 'POST #zai_webhook' do
    context 'with valid signature' do
      it 'processes the webhook' do
        signature = ZaiPayment::Resources::Webhook.new.generate_signature(
          payload, secret_key, timestamp
        )
        
        request.headers['Webhooks-signature'] = "t=#{timestamp},v=#{signature}"
        post :zai_webhook, body: payload
        
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid signature' do
      it 'rejects the webhook' do
        request.headers['Webhooks-signature'] = "t=#{timestamp},v=invalid_sig"
        post :zai_webhook, body: payload
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

### Troubleshooting

#### Common Issues

1. **"Invalid signature header: missing or invalid timestamp"**
   - Ensure the header format is correct: `t=timestamp,v=signature`
   - Check that timestamp is a valid Unix timestamp

2. **"Webhook timestamp is outside tolerance"**
   - Check your server's clock synchronization (use NTP)
   - Increase the tolerance if network latency is high
   - Log the timestamp difference to diagnose timing issues

3. **Signature doesn't match**
   - Verify you're using the raw request body (not parsed JSON)
   - Ensure the secret key matches what you registered with Zai
   - Check for any character encoding issues

#### Debugging Tips

```ruby
# Enable detailed logging for debugging
def verify_webhook_with_logging(payload, signature_header, secret_key)
  webhook = ZaiPayment::Resources::Webhook.new
  
  begin
    # Extract timestamp and signature
    timestamp = signature_header.match(/t=(\d+)/)[1].to_i
    signature = signature_header.match(/v=([^,]+)/)[1]
    
    # Log details
    Rails.logger.debug "Webhook timestamp: #{timestamp}"
    Rails.logger.debug "Current time: #{Time.now.to_i}"
    Rails.logger.debug "Time difference: #{Time.now.to_i - timestamp}s"
    Rails.logger.debug "Payload length: #{payload.bytesize} bytes"
    
    # Generate expected signature for comparison
    expected = webhook.generate_signature(payload, secret_key, timestamp)
    Rails.logger.debug "Expected signature: #{expected[0..10]}..."
    Rails.logger.debug "Received signature: #{signature[0..10]}..."
    
    # Verify
    webhook.verify_signature(
      payload: payload,
      signature_header: signature_header,
      secret_key: secret_key
    )
  rescue => e
    Rails.logger.error "Verification failed: #{e.message}"
    false
  end
end
```

### Security Best Practices

1. **Always Verify Signatures**: Never process webhooks without verification in production
2. **Use HTTPS**: Ensure your webhook endpoint uses HTTPS
3. **Implement Rate Limiting**: Protect against DoS attacks
4. **Log Failed Attempts**: Monitor for suspicious activity
5. **Rotate Secrets**: Periodically update your secret key
6. **Use Environment Variables**: Never hardcode secret keys
7. **Validate Payload**: After verifying the signature, validate the payload structure
8. **Idempotency**: Design webhook handlers to be idempotent (safe to replay)

### References

- [Zai Webhook Signature Documentation](https://developer.hellozai.com/docs/verify-webhook-signatures)
- [Create Secret Key API](https://developer.hellozai.com/reference/createsecretkey)

## API Reference

For the official Zai API documentation, see:
- [List Webhooks](https://developer.hellozai.com/reference/getallwebhooks)
- [Show Webhook](https://developer.hellozai.com/reference/getwebhookbyid)
- [Create Webhook](https://developer.hellozai.com/reference/createwebhook)
- [Update Webhook](https://developer.hellozai.com/reference/updatewebhook)
- [Delete Webhook](https://developer.hellozai.com/reference/deletewebhookbyid)

