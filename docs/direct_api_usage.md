# Direct API Usage Guide

This guide shows you how to use the ZaiPayment client directly to call APIs that haven't been implemented as resource methods yet.

## Overview

The `ZaiPayment::Client` class provides low-level HTTP methods (`get`, `post`, `patch`, `delete`) that you can use to call any Zai API endpoint directly.

## Basic Usage

### Creating a Client

```ruby
# Use the default client (va_base endpoint)
client = ZaiPayment::Client.new

# Or specify a different endpoint
client = ZaiPayment::Client.new(base_endpoint: :core_base)
```

### Available Endpoints

The client supports different base endpoints configured in your setup:
- `:va_base` - Virtual Account API base (default)
- `:core_base` - Core API base (for users, items, etc.)

## HTTP Methods

The client provides four HTTP methods:

### GET Request
```ruby
client.get(path, params: {})
```

### POST Request
```ruby
client.post(path, body: {})
```

### PATCH Request
```ruby
client.patch(path, body: {})
```

### DELETE Request
```ruby
client.delete(path)
```

## Examples

### Example 1: Get Wallet Account Transactions (Unimplemented)

```ruby
# If wallet transactions endpoint isn't implemented yet
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# Get transactions for a wallet account
response = client.get("/wallet_accounts/#{wallet_id}/transactions", params: {
  limit: 20,
  offset: 0
})

if response.success?
  transactions = response.data
  transactions.each do |transaction|
    puts "Transaction ID: #{transaction['id']}"
    puts "Amount: #{transaction['amount']} #{transaction['currency']}"
    puts "Type: #{transaction['type']}"
    puts "State: #{transaction['state']}"
    puts "---"
  end
else
  puts "Error: #{response.status}"
end
```

### Example 2: Create Virtual Account (Unimplemented)

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# Create a virtual account for a wallet
response = client.post("/wallet_accounts/#{wallet_id}/virtual_accounts", body: {
  account_name: "My Virtual Account",
  nickname: "main_account"
})

if response.success?
  virtual_account = response.data
  puts "Virtual Account Created!"
  puts "ID: #{virtual_account['id']}"
  puts "Account Number: #{virtual_account['account_number']}"
  puts "BSB: #{virtual_account['bsb']}"
else
  puts "Error: #{response.status}"
end
```

### Example 3: Get NPP Details (Unimplemented)

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# Get NPP (New Payments Platform) details for a wallet account
response = client.get("/wallet_accounts/#{wallet_id}/npp_details")

if response.success?
  npp_details = response.data
  puts "NPP PayID: #{npp_details['pay_id']}"
  puts "PayID Type: #{npp_details['pay_id_type']}"
  puts "Status: #{npp_details['status']}"
end
```

### Example 4: Batch Transactions (Unimplemented)

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# Create a batch transaction
response = client.post("/batch_transactions", body: {
  account_id: account_id,
  batch_name: "Monthly Payouts",
  transactions: [
    {
      amount: 10000,
      currency: "AUD",
      to_user_id: user_id_1,
      description: "Payout to user 1"
    },
    {
      amount: 15000,
      currency: "AUD", 
      to_user_id: user_id_2,
      description: "Payout to user 2"
    }
  ]
})

if response.success?
  batch = response.data
  puts "Batch Transaction Created!"
  puts "Batch ID: #{batch['id']}"
  puts "Status: #{batch['status']}"
  puts "Total Amount: #{batch['total_amount']}"
end
```

### Example 5: Update Item Fee (Unimplemented)

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# Update a fee for an item
response = client.patch("/items/#{item_id}/fees/#{fee_id}", body: {
  amount: 500,
  description: "Updated processing fee"
})

if response.success?
  fee = response.data
  puts "Fee Updated!"
  puts "New Amount: #{fee['amount']}"
end
```

### Example 6: List Card Accounts (Unimplemented)

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

# List all card accounts with pagination
response = client.get("/card_accounts", params: {
  limit: 50,
  offset: 0,
  user_id: user_id  # Optional filter
})

if response.success?
  card_accounts = response.data
  card_accounts.each do |card|
    puts "Card ID: #{card['id']}"
    puts "Card Type: #{card['card']['type']}"
    puts "Last 4 Digits: #{card['card']['number']}"
    puts "Active: #{card['active']}"
    puts "---"
  end
  
  # Access pagination metadata
  meta = response.meta
  puts "\nTotal: #{meta['total']}"
  puts "Showing #{meta['limit']} items from offset #{meta['offset']}"
end
```

### Example 7: Custom Endpoint with Error Handling

```ruby
client = ZaiPayment::Client.new(base_endpoint: :core_base)

begin
  # Call any custom endpoint
  response = client.get("/custom/endpoint/path", params: {
    custom_param: "value"
  })
  
  if response.success?
    data = response.data
    puts "Success: #{data.inspect}"
  else
    puts "API Error: #{response.status}"
  end
  
rescue ZaiPayment::Errors::TimeoutError => e
  puts "Request timed out: #{e.message}"
rescue ZaiPayment::Errors::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Unauthorized: #{e.message}"
  # Maybe refresh token here
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

## Advanced: Using Client in a Custom Resource

If you're implementing a new resource that's not yet part of the gem, you can follow this pattern:

```ruby
module ZaiPayment
  module Resources
    class CustomResource
      attr_reader :client
      
      def initialize(client: nil)
        @client = client || Client.new(base_endpoint: :core_base)
      end
      
      # List custom resources
      def list(limit: 10, offset: 0)
        params = { limit: limit, offset: offset }
        client.get("/custom_resources", params: params)
      end
      
      # Get a custom resource
      def show(resource_id)
        client.get("/custom_resources/#{resource_id}")
      end
      
      # Create a custom resource
      def create(name:, description:)
        body = {
          name: name,
          description: description
        }
        client.post("/custom_resources", body: body)
      end
      
      # Update a custom resource
      def update(resource_id, **attributes)
        body = build_body(attributes)
        client.patch("/custom_resources/#{resource_id}", body: body)
      end
      
      # Delete a custom resource
      def delete(resource_id)
        client.delete("/custom_resources/#{resource_id}")
      end
      
      private
      
      def build_body(attributes)
        # Filter and transform attributes as needed
        attributes.compact
      end
    end
  end
end

# Usage
custom = ZaiPayment::Resources::CustomResource.new
response = custom.list(limit: 20)
```

## Response Object

All client methods return a `ZaiPayment::Response` object with the following methods:

### Response Methods

```ruby
response.success?       # => true/false (2xx status codes)
response.client_error?  # => true/false (4xx status codes)
response.server_error?  # => true/false (5xx status codes)
response.status         # => HTTP status code (e.g., 200, 404, 500)
response.data           # => Extracted data from response body
response.body           # => Full response body
response.meta           # => Pagination/metadata (if available)
response.headers        # => Response headers
```

### Response Data Extraction

The `response.data` method automatically extracts the main data from the response:

```ruby
# For endpoints returning users
response.data  # Automatically extracts response.body['users']

# For endpoints returning items  
response.data  # Automatically extracts response.body['items']

# For endpoints returning wallet_accounts
response.data  # Automatically extracts response.body['wallet_accounts']

# For custom endpoints without a recognized key
response.data  # Returns the full response.body
```

Supported auto-extraction keys:
- `webhooks`
- `users`
- `items`
- `fees`
- `transactions`
- `batch_transactions`
- `bpay_accounts`
- `bank_accounts`
- `card_accounts`
- `wallet_accounts`
- `routing_number`

## Error Handling

The client automatically handles errors and raises appropriate exceptions:

### Available Error Classes

```ruby
ZaiPayment::Errors::BadRequestError       # 400 Bad Request
ZaiPayment::Errors::UnauthorizedError     # 401 Unauthorized
ZaiPayment::Errors::ForbiddenError        # 403 Forbidden
ZaiPayment::Errors::NotFoundError         # 404 Not Found
ZaiPayment::Errors::ValidationError       # 422 Unprocessable Entity
ZaiPayment::Errors::RateLimitError        # 429 Too Many Requests
ZaiPayment::Errors::ServerError           # 5xx Server Errors
ZaiPayment::Errors::TimeoutError          # Timeout errors
ZaiPayment::Errors::ConnectionError       # Connection errors
ZaiPayment::Errors::ApiError              # Generic API errors
```

### Error Handling Example

```ruby
begin
  response = client.get("/some/endpoint")
  data = response.data
  # Process data...
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Auth failed, refreshing token..."
  ZaiPayment.refresh_token!
  retry
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

## Configuration

The client uses the global ZaiPayment configuration:

```ruby
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.environment = :prelive  # or :production
  
  # Optional timeout configuration
  config.timeout = 60          # Overall timeout
  config.open_timeout = 10     # Connection timeout
  config.read_timeout = 50     # Read timeout
end
```

## Best Practices

1. **Use Appropriate Endpoint**: Choose `:core_base` for user/item/transaction APIs, `:va_base` for virtual account APIs

2. **Handle Errors Gracefully**: Always wrap API calls in error handling blocks

3. **Check Response Status**: Always check `response.success?` before accessing data

4. **Use Response.data**: Prefer `response.data` over `response.body` for automatic extraction

5. **Follow API Conventions**: Use the same patterns as existing resource classes when building custom resources

6. **Document Your Usage**: When using direct API calls, document the endpoint and expected responses

7. **Consider Contributing**: If you implement a useful endpoint, consider contributing it back to the gem!

## Need Help?

- Check the [Zai API Documentation](https://developer.hellozai.com/)
- Review existing resource implementations in `lib/zai_payment/resources/`
- Open an issue on GitHub if you find a commonly-used endpoint that should be added to the gem

## Example: Complete Workflow

Here's a complete example workflow using direct API calls:

```ruby
require 'zai_payment'

# Configure the gem
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.environment = :prelive
end

# Initialize client
client = ZaiPayment::Client.new(base_endpoint: :core_base)

begin
  # 1. Get user's wallet account
  wallet_response = ZaiPayment.users.wallet_account('user_123')
  wallet = wallet_response.data
  wallet_id = wallet['id']
  
  puts "Wallet Balance: #{wallet['balance']} #{wallet['currency']}"
  
  # 2. Get wallet transactions (using direct API call)
  transactions_response = client.get(
    "/wallet_accounts/#{wallet_id}/transactions",
    params: { limit: 10, offset: 0 }
  )
  
  if transactions_response.success?
    transactions = transactions_response.data
    puts "\nRecent Transactions:"
    transactions.each do |txn|
      puts "- #{txn['type']}: #{txn['amount']} (#{txn['state']})"
    end
  end
  
  # 3. Get NPP details (using direct API call)
  npp_response = client.get("/wallet_accounts/#{wallet_id}/npp_details")
  
  if npp_response.success?
    npp = npp_response.data
    puts "\nNPP Details:"
    puts "PayID: #{npp['pay_id']}"
    puts "Status: #{npp['status']}"
  end
  
  # 4. Create a virtual account (using direct API call)
  virtual_response = client.post(
    "/wallet_accounts/#{wallet_id}/virtual_accounts",
    body: {
      account_name: "My Virtual Account",
      nickname: "savings"
    }
  )
  
  if virtual_response.success?
    virtual = virtual_response.data
    puts "\nVirtual Account Created!"
    puts "Account Number: #{virtual['account_number']}"
    puts "BSB: #{virtual['bsb']}"
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

This guide should help you call any Zai API endpoint, even if it hasn't been implemented in the gem yet!

