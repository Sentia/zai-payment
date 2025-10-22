# Authentication Guide

## Overview

The Zai Payment gem implements **OAuth2 Client Credentials flow** for secure authentication with the Zai API. The gem intelligently manages your authentication tokens behind the scenes with automatic caching and refresh.

### Key Features

✅ **Automatic token management** - Tokens are cached and reused  
✅ **Smart refresh** - Tokens refresh automatically before expiration  
✅ **Thread-safe** - Safe for concurrent requests  
✅ **Zero maintenance** - Set it once, forget about it  
✅ **60-minute token lifetime** - Handled automatically by the gem  

---

## Configuration

Before authentication, configure your Zai credentials:

```ruby
# config/initializers/zai_payment.rb
ZaiPayment.configure do |config|
  config.environment   = :prelive # or :production
  config.client_id     = ENV.fetch('ZAI_CLIENT_ID')
  config.client_secret = ENV.fetch('ZAI_CLIENT_SECRET')
  config.scope         = ENV.fetch('ZAI_OAUTH_SCOPE')
  
  # Optional: Configure timeouts
  config.timeout       = 30  # Request timeout in seconds (default: 60)
  config.open_timeout  = 10  # Connection timeout in seconds (default: 60)
end
```

### Environment Variables

Store your credentials securely in environment variables:

```bash
# .env
ZAI_CLIENT_ID=your_client_id
ZAI_CLIENT_SECRET=your_client_secret
ZAI_OAUTH_SCOPE=your_scope
```

⚠️ **Never commit credentials to version control!**

---

## Getting Tokens: Two Approaches

### Approach 1: Short Way (Recommended) ⭐

The simplest way to get an authenticated token - perfect for most use cases:

```ruby
# Get a token with automatic management
token = ZaiPayment.token

# Returns: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**When to use:**
- ✅ Most common use case
- ✅ When you just need a token quickly
- ✅ When using the gem's built-in resources (webhooks, etc.)
- ✅ For simple integrations

**Benefits:**
- One-liner simplicity
- Uses global configuration
- Automatic token management
- Thread-safe

### Approach 2: Long Way (Advanced)

For advanced use cases where you need more control:

```ruby
# Create your own configuration
config = ZaiPayment::Config.new
config.environment   = :prelive
config.client_id     = 'your_client_id'
config.client_secret = 'your_client_secret'
config.scope         = 'your_scope'

# Create a token provider instance
token_provider = ZaiPayment::Auth::TokenProvider.new(config: config)

# Get the bearer token
token = token_provider.bearer_token

# Returns: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**When to use:**
- ✅ Multiple Zai accounts/configurations
- ✅ Custom token stores (e.g., Redis)
- ✅ Testing with different configurations
- ✅ Advanced authentication scenarios

**Benefits:**
- Full control over configuration
- Can create multiple instances
- Custom token storage
- Useful for testing

---

## How Token Management Works

### Automatic Caching

The gem automatically caches tokens to avoid unnecessary API calls:

```ruby
# First call - fetches from Zai API
token1 = ZaiPayment.token
# => Makes API call to get token

# Subsequent calls - uses cached token
token2 = ZaiPayment.token
# => Returns cached token (no API call)

token1 == token2  # => true
```

### Automatic Refresh

Tokens expire after 60 minutes. The gem monitors expiration and refreshes automatically:

```ruby
# Token expires in 60 minutes
token = ZaiPayment.token

# ... 59 minutes later ...
same_token = ZaiPayment.token  # Still cached

# ... 61 minutes later ...
new_token = ZaiPayment.token  # Automatically refreshed!
```

### Token Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│ 1. Request Token                                        │
│    ZaiPayment.token                                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Check Cache                                          │
│    • Token exists? → Check if expired                   │
│    • Token expired? → Fetch new token                   │
│    • No token? → Fetch new token                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Fetch Token (if needed)                              │
│    POST https://auth.api.hellozai.com/oauth/token       │
│    • Grant type: client_credentials                     │
│    • Credentials: client_id + client_secret             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 4. Cache Token                                          │
│    • Store token in memory                              │
│    • Store expiration time (expires_in - buffer)        │
│    • Thread-safe storage with Mutex                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Return Token                                         │
│    "Bearer eyJhbGc..."                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### Basic Usage

```ruby
# Simple token retrieval
token = ZaiPayment.token
puts token
# => "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Use with your own HTTP requests
require 'faraday'

connection = Faraday.new(url: 'https://api.hellozai.com') do |f|
  f.request :json
  f.response :json
  f.adapter Faraday.default_adapter
end

response = connection.get('/some-endpoint') do |req|
  req.headers['Authorization'] = ZaiPayment.token
  req.headers['Content-Type'] = 'application/json'
end
```

### Using Built-in Resources

The gem's resources automatically handle authentication:

```ruby
# No need to manually get tokens!
# The gem handles it automatically

response = ZaiPayment.webhooks.list
# Internally uses ZaiPayment.token

response = ZaiPayment.webhooks.create(
  url: 'https://example.com/webhook',
  object_type: 'transactions'
)
# Authentication handled automatically
```

### Multiple Configurations

For managing multiple Zai accounts:

```ruby
# Account 1 (Production)
prod_config = ZaiPayment::Config.new
prod_config.environment = :production
prod_config.client_id = ENV['ZAI_PROD_CLIENT_ID']
prod_config.client_secret = ENV['ZAI_PROD_CLIENT_SECRET']
prod_config.scope = ENV['ZAI_PROD_SCOPE']

prod_token_provider = ZaiPayment::Auth::TokenProvider.new(config: prod_config)
prod_client = ZaiPayment::Client.new(
  config: prod_config,
  token_provider: prod_token_provider
)

# Account 2 (Prelive/Testing)
prelive_config = ZaiPayment::Config.new
prelive_config.environment = :prelive
prelive_config.client_id = ENV['ZAI_PRELIVE_CLIENT_ID']
prelive_config.client_secret = ENV['ZAI_PRELIVE_CLIENT_SECRET']
prelive_config.scope = ENV['ZAI_PRELIVE_SCOPE']

prelive_token_provider = ZaiPayment::Auth::TokenProvider.new(config: prelive_config)
prelive_client = ZaiPayment::Client.new(
  config: prelive_config,
  token_provider: prelive_token_provider
)

# Use different clients for different accounts
prod_webhooks = ZaiPayment::Resources::Webhook.new(client: prod_client)
prelive_webhooks = ZaiPayment::Resources::Webhook.new(client: prelive_client)
```

### Rails Controller Example

```ruby
class ZaiController < ApplicationController
  before_action :ensure_authenticated

  def index
    # Token is already validated
    response = ZaiPayment.webhooks.list
    render json: response.data
  end

  private

  def ensure_authenticated
    begin
      # This will raise an error if authentication fails
      ZaiPayment.token
    rescue ZaiPayment::Errors::UnauthorizedError => e
      render json: { error: 'Authentication failed' }, status: :unauthorized
    rescue ZaiPayment::Errors::ApiError => e
      render json: { error: 'API error' }, status: :service_unavailable
    end
  end
end
```

---

## Testing

### RSpec Setup

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.before(:suite) do
    # Configure for testing
    ZaiPayment.configure do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end
  end
end
```

### Mocking Authentication

```ruby
# spec/support/zai_payment_helpers.rb
module ZaiPaymentHelpers
  def mock_zai_authentication
    allow(ZaiPayment).to receive(:token).and_return('Bearer mock_token')
  end

  def mock_token_provider
    token_provider = instance_double(
      ZaiPayment::Auth::TokenProvider,
      bearer_token: 'Bearer test_token'
    )
    allow(ZaiPayment::Auth::TokenProvider).to receive(:new).and_return(token_provider)
    token_provider
  end
end

RSpec.configure do |config|
  config.include ZaiPaymentHelpers
end
```

### Test Example

```ruby
require 'rails_helper'

RSpec.describe 'Zai Authentication' do
  describe 'token retrieval' do
    it 'returns a valid bearer token' do
      mock_zai_authentication
      
      token = ZaiPayment.token
      expect(token).to start_with('Bearer ')
      expect(token.length).to be > 20
    end
  end

  describe 'with custom configuration' do
    it 'uses custom credentials' do
      config = ZaiPayment::Config.new
      config.environment = :prelive
      config.client_id = 'custom_id'
      config.client_secret = 'custom_secret'
      config.scope = 'custom_scope'

      token_provider = ZaiPayment::Auth::TokenProvider.new(config: config)
      
      # Mock the HTTP request
      allow(token_provider).to receive(:bearer_token).and_return('Bearer custom_token')
      
      expect(token_provider.bearer_token).to eq('Bearer custom_token')
    end
  end
end
```

---

## Advanced Topics

### Thread Safety

The gem uses a Mutex to ensure thread-safe token storage:

```ruby
# Safe for concurrent requests
threads = 10.times.map do
  Thread.new do
    token = ZaiPayment.token
    # All threads share the same cached token
  end
end

threads.each(&:join)
```

### Token Store

The default token store is in-memory. For production systems with multiple servers, consider implementing a shared store:

```ruby
# Future: Custom token store (Redis example)
class RedisTokenStore
  def initialize(redis_client)
    @redis = redis_client
  end

  def get(key)
    @redis.get(key)
  end

  def set(key, value, expires_in:)
    @redis.setex(key, expires_in, value)
  end
end

# This is a planned feature
```

### Timeout Configuration

Configure timeouts for authentication requests:

```ruby
ZaiPayment.configure do |config|
  config.environment = :production
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_OAUTH_SCOPE']
  
  # Set timeouts (in seconds)
  config.timeout = 30        # Total request timeout
  config.open_timeout = 10   # Connection establishment timeout
end
```

---

## Error Handling

### Common Errors

```ruby
begin
  token = ZaiPayment.token
rescue ZaiPayment::Errors::UnauthorizedError => e
  # Invalid credentials (401)
  puts "Authentication failed: #{e.message}"
  # Check your client_id and client_secret
  
rescue ZaiPayment::Errors::TimeoutError => e
  # Request timed out
  puts "Request timeout: #{e.message}"
  # Consider increasing timeout values
  
rescue ZaiPayment::Errors::ConnectionError => e
  # Network connection failed
  puts "Connection error: #{e.message}"
  # Check network connectivity
  
rescue ZaiPayment::Errors::ApiError => e
  # Other API errors
  puts "API error: #{e.message}"
end
```

### Handling Authentication Failures

```ruby
def safely_get_token
  retries = 0
  max_retries = 3

  begin
    ZaiPayment.token
  rescue ZaiPayment::Errors::TimeoutError => e
    retries += 1
    if retries < max_retries
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise
    end
  end
end
```

---

## Best Practices

### ✅ Do's

✅ **Store credentials in environment variables**
```ruby
config.client_id = ENV.fetch('ZAI_CLIENT_ID')
```

✅ **Use the short way for simple cases**
```ruby
token = ZaiPayment.token
```

✅ **Configure once, use everywhere**
```ruby
# config/initializers/zai_payment.rb
ZaiPayment.configure { |c| ... }
```

✅ **Let the gem handle token refresh**
```ruby
# Don't manually refresh - it's automatic!
token = ZaiPayment.token
```

✅ **Use built-in resources**
```ruby
ZaiPayment.webhooks.list  # Authentication automatic
```

### ❌ Don'ts

❌ **Don't hardcode credentials**
```ruby
# BAD!
config.client_id = 'abc123'
```

❌ **Don't manually manage tokens**
```ruby
# BAD! The gem does this for you
if token_expired?
  fetch_new_token
end
```

❌ **Don't create new providers unnecessarily**
```ruby
# BAD! Use the global instance
100.times { ZaiPayment::Auth::TokenProvider.new }
```

❌ **Don't commit credentials to git**
```bash
# BAD!
git add .env
```

---

## Troubleshooting

### "Invalid client credentials"

**Problem:** Authentication returns 401 Unauthorized

**Solutions:**
1. Verify `client_id` and `client_secret` are correct
2. Check that credentials match the environment (prelive vs production)
3. Ensure scope is valid for your account
4. Confirm credentials are active in Zai dashboard

### "Token expired" errors

**Problem:** Getting errors about expired tokens

**Solution:** This shouldn't happen! The gem auto-refreshes. If you see this:
1. Check if you're caching tokens manually (don't do this)
2. Ensure you're using `ZaiPayment.token` correctly
3. Report as a bug if the issue persists

### Connection timeouts

**Problem:** Requests timing out during authentication

**Solutions:**
1. Increase timeout values in config
2. Check network connectivity
3. Verify firewall isn't blocking requests
4. Test network latency to Zai API

### Multiple configurations not working

**Problem:** Different configs getting mixed up

**Solution:** Ensure you're creating separate instances:
```ruby
# Good - separate instances
provider1 = ZaiPayment::Auth::TokenProvider.new(config: config1)
provider2 = ZaiPayment::Auth::TokenProvider.new(config: config2)

# Bad - sharing global config
ZaiPayment.configure { |c| config1 }
token1 = ZaiPayment.token
ZaiPayment.configure { |c| config2 }
token2 = ZaiPayment.token  # Will overwrite first config!
```

---

## API Reference

### Configuration

```ruby
ZaiPayment.configure do |config|
  config.environment    # :prelive or :production (required)
  config.client_id      # String (required)
  config.client_secret  # String (required)
  config.scope          # String (required)
  config.timeout        # Integer, seconds (optional, default: 60)
  config.open_timeout   # Integer, seconds (optional, default: 60)
end
```

### Methods

#### `ZaiPayment.token`
Returns a bearer token string.

**Returns:** `String` - Bearer token (e.g., "Bearer eyJhbG...")  
**Raises:** `UnauthorizedError`, `TimeoutError`, `ConnectionError`, `ApiError`

#### `ZaiPayment::Auth::TokenProvider.new(config:)`
Creates a new token provider instance.

**Parameters:**
- `config` - `ZaiPayment::Config` instance

**Returns:** `TokenProvider` instance

#### `TokenProvider#bearer_token`
Gets or refreshes the bearer token.

**Returns:** `String` - Bearer token  
**Raises:** `UnauthorizedError`, `TimeoutError`, `ConnectionError`, `ApiError`

---

## External Resources

- [Zai OAuth2 Documentation](https://developer.hellozai.com/reference/overview#authentication)
- [OAuth2 Client Credentials Flow](https://oauth.net/2/grant-types/client-credentials/)
- [Zai API Reference](https://developer.hellozai.com/reference)

---

## Next Steps

- ✅ Authentication configured and working
- 📖 Read [Webhook Guide](WEBHOOKS.md) to start using webhooks
- 💡 Check [Examples](../examples/webhooks.md) for complete code samples
- 🔒 Set up [Webhook Security](WEBHOOK_SECURITY_QUICKSTART.md)

