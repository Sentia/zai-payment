# Webhook Examples

This file demonstrates how to use the ZaiPayment webhook functionality.

## Setup

```ruby
require 'zai_payment'

# Configure the gem
ZaiPayment.configure do |config|
  config.environment = :prelive # or :production
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.scope = 'your_scope'
end
```

## List Webhooks

```ruby
# Get all webhooks
response = ZaiPayment.webhooks.list
puts response.data # Array of webhooks
puts response.meta # Pagination metadata

# With pagination
response = ZaiPayment.webhooks.list(limit: 20, offset: 10)
```

## Show a Specific Webhook

```ruby
webhook_id = 'webhook_123'
response = ZaiPayment.webhooks.show(webhook_id)

webhook = response.data
puts webhook['id']
puts webhook['url']
puts webhook['object_type']
puts webhook['enabled']
```

## Create a Webhook

```ruby
response = ZaiPayment.webhooks.create(
  url: 'https://example.com/webhooks/zai',
  object_type: 'transactions',
  enabled: true,
  description: 'Production webhook for transactions'
)

new_webhook = response.data
puts "Created webhook with ID: #{new_webhook['id']}"
```

## Update a Webhook

```ruby
webhook_id = 'webhook_123'

# Update specific fields
response = ZaiPayment.webhooks.update(
  webhook_id,
  enabled: false,
  description: 'Temporarily disabled'
)

# Or update multiple fields
response = ZaiPayment.webhooks.update(
  webhook_id,
  url: 'https://example.com/webhooks/zai-v2',
  object_type: 'items',
  enabled: true
)
```

## Delete a Webhook

```ruby
webhook_id = 'webhook_123'
response = ZaiPayment.webhooks.delete(webhook_id)

if response.success?
  puts "Webhook deleted successfully"
end
```

## Error Handling

```ruby
begin
  response = ZaiPayment.webhooks.create(
    url: 'https://example.com/webhook',
    object_type: 'transactions'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication failed: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

## Using Custom Client Instance

If you need more control, you can create your own client instance:

```ruby
config = ZaiPayment::Config.new
config.environment = :prelive
config.client_id = 'your_client_id'
config.client_secret = 'your_client_secret'
config.scope = 'your_scope'

token_provider = ZaiPayment::Auth::TokenProvider.new(config: config)
client = ZaiPayment::Client.new(config: config, token_provider: token_provider)

webhooks = ZaiPayment::Resources::Webhook.new(client: client)
response = webhooks.list
```

## Response Object

All webhook methods return a `ZaiPayment::Response` object with the following methods:

```ruby
response = ZaiPayment.webhooks.list

# Check status
response.success?       # => true/false (2xx status)
response.client_error?  # => true/false (4xx status)
response.server_error?  # => true/false (5xx status)

# Access data
response.data           # => Main response data (array or hash)
response.meta           # => Pagination metadata (if available)
response.body           # => Raw response body
response.headers        # => Response headers
response.status         # => HTTP status code
```

