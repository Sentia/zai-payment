# Token Auth API

## Overview

The TokenAuth resource provides secure token generation for collecting bank account and credit card information. These tokens are used with the PromisePay.js library to securely transmit sensitive payment data without it ever touching your server.

This is particularly useful for PCI compliance when collecting credit card information, and for securely collecting bank account details.

## Table of Contents

- [When to Use Token Auth](#when-to-use-token-auth)
- [How It Works](#how-it-works)
- [API Methods](#api-methods)
- [Token Types](#token-types)
- [Security Considerations](#security-considerations)
- [Integration Guide](#integration-guide)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## When to Use Token Auth

You should use Token Auth when you need to:

1. **Collect Credit Card Information** - Generate a card token for buyers to securely enter their credit card details
2. **Collect Bank Account Details** - Generate a bank token for sellers to securely provide their bank account information
3. **PCI Compliance** - Ensure sensitive payment data never touches your server
4. **Frontend Integration** - Use with PromisePay.js to handle payment data collection on the client side

## How It Works

```
1. Backend (Your Server)
   ↓
   Generate token using ZaiPayment.token_auths.generate()
   ↓
   Return token to frontend
   
2. Frontend (Browser/App)
   ↓
   Use PromisePay.js with the token
   ↓
   User enters payment details
   ↓
   PromisePay.js sends data directly to Zai (not your server)
   ↓
   Returns payment account ID
   
3. Backend (Your Server)
   ↓
   Use payment account ID to create items/transactions
```

## API Methods

### `generate(user_id:, token_type:)`

Generate a token for bank or card account data collection.

**Parameters:**
- `user_id` (String, required) - The ID of the buyer or seller user (already created)
- `token_type` (String, optional) - Type of token to generate: `'bank'` or `'card'` (default: `'bank'`)

**Returns:**
- `Response` object containing the generated token and metadata

**Example:**

```ruby
# Generate a bank token
response = ZaiPayment.token_auths.generate(
  user_id: "seller-68611249",
  token_type: "bank"
)

token = response.data['token_auth']['token']
# => "tok_bank_abc123xyz..."
```

## Token Types

### Bank Tokens

Bank tokens are used to collect bank account information from payout users (sellers/merchants).

**Use Case:** Collecting bank account details for disbursements to sellers.

**Typical Flow:**
1. Create a payout user (seller)
2. Generate a bank token for the seller
3. Send token to frontend
4. Use PromisePay.js to collect bank account details
5. Receive bank account ID from Zai
6. Associate bank account with items/transactions

**Example:**

```ruby
# Step 1: Create seller
seller = ZaiPayment.users.create(
  user_type: "payout",
  email: "seller@example.com",
  first_name: "Jane",
  last_name: "Smith",
  country: "AUS",
  dob: "01/01/1990",
  address_line1: "456 Market St",
  city: "Sydney",
  state: "NSW",
  zip: "2000"
)

seller_id = seller.data['users']['id']

# Step 2: Generate bank token
token_response = ZaiPayment.token_auths.generate(
  user_id: seller_id,
  token_type: "bank"
)

bank_token = token_response.data['token_auth']['token']

# Step 3: Send to frontend for PromisePay.js integration
```

### Card Tokens

Card tokens are used to collect credit card information from payin users (buyers).

**Use Case:** Collecting credit card details for payments from buyers.

**Typical Flow:**
1. Create a payin user (buyer)
2. Generate a card token for the buyer
3. Send token to frontend
4. Use PromisePay.js to collect credit card details
5. Receive card account ID from Zai
6. Use card account to process payments

**Example:**

```ruby
# Step 1: Create buyer
buyer = ZaiPayment.users.create(
  user_type: "payin",
  email: "buyer@example.com",
  first_name: "John",
  last_name: "Doe",
  country: "USA"
)

buyer_id = buyer.data['users']['id']

# Step 2: Generate card token
token_response = ZaiPayment.token_auths.generate(
  user_id: buyer_id,
  token_type: "card"
)

card_token = token_response.data['token_auth']['token']

# Step 3: Send to frontend for PromisePay.js integration
```

## Security Considerations

### Token Expiration

Tokens have a limited lifespan (typically 1 hour). Always:
- Check the `expires_at` field in the response
- Generate fresh tokens for each payment session
- Don't store tokens for later use
- Handle token expiration gracefully on the frontend

### Token Scope

Each token is:
- **User-specific**: Tied to a single user ID
- **Single-use**: Should be used once per payment session
- **Type-specific**: Bank tokens only for bank accounts, card tokens only for cards

### PCI Compliance

Token Auth helps maintain PCI compliance by:
- Preventing card data from touching your server
- Using secure HTTPS transmission
- Leveraging Zai's PCI-compliant infrastructure
- Minimizing your PCI scope

## Integration Guide

### Backend Integration

```ruby
# app/controllers/payment_tokens_controller.rb
class PaymentTokensController < ApplicationController
  before_action :authenticate_user!
  
  def create
    user_id = current_user.zai_user_id
    token_type = params[:token_type] || 'card'
    
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: token_type
    )
    
    render json: {
      token: response.data['token_auth']['token'],
      expires_at: response.data['token_auth']['expires_at']
    }
  rescue ZaiPayment::Errors::ApiError => e
    render json: { error: e.message }, status: :bad_gateway
  end
end
```

### Frontend Integration (JavaScript)

```html
<!-- Include PromisePay.js -->
<script src="https://cdn.assemblypay.com/promisepay.js"></script>

<script>
  // 1. Fetch token from your backend
  async function getPaymentToken(tokenType) {
    const response = await fetch('/api/payment_tokens', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token_type: tokenType })
    });
    
    const data = await response.json();
    return data.token;
  }
  
  // 2. Use token with PromisePay.js to collect card details
  async function collectCardDetails() {
    const token = await getPaymentToken('card');
    
    PromisePay.setToken(token);
    
    PromisePay.createCardAccount({
      card_number: document.getElementById('card_number').value,
      expiry_month: document.getElementById('expiry_month').value,
      expiry_year: document.getElementById('expiry_year').value,
      cvv: document.getElementById('cvv').value
    }, function(response) {
      if (response.error) {
        console.error('Error:', response.error);
      } else {
        // Card account created successfully
        const cardAccountId = response.card_accounts.id;
        // Send cardAccountId to your backend to create item/transaction
        processPayment(cardAccountId);
      }
    });
  }
  
  // 3. Use token with PromisePay.js to collect bank details
  async function collectBankDetails() {
    const token = await getPaymentToken('bank');
    
    PromisePay.setToken(token);
    
    PromisePay.createBankAccount({
      account_name: document.getElementById('account_name').value,
      account_number: document.getElementById('account_number').value,
      routing_number: document.getElementById('routing_number').value,
      account_type: 'savings' // or 'checking'
    }, function(response) {
      if (response.error) {
        console.error('Error:', response.error);
      } else {
        // Bank account created successfully
        const bankAccountId = response.bank_accounts.id;
        // Send bankAccountId to your backend
        saveBankAccount(bankAccountId);
      }
    });
  }
</script>
```

### Complete Payment Flow

```ruby
# 1. Create users (buyer and seller)
buyer = ZaiPayment.users.create(
  user_type: "payin",
  email: "buyer@example.com",
  first_name: "John",
  last_name: "Doe",
  country: "USA"
)

seller = ZaiPayment.users.create(
  user_type: "payout",
  email: "seller@example.com",
  first_name: "Jane",
  last_name: "Smith",
  country: "AUS",
  dob: "01/01/1990",
  address_line1: "456 Market St",
  city: "Sydney",
  state: "NSW",
  zip: "2000"
)

# 2. Generate card token for buyer
card_token_response = ZaiPayment.token_auths.generate(
  user_id: buyer.data['users']['id'],
  token_type: "card"
)

# Send card_token to frontend, collect card details, get card_account_id

# 3. Generate bank token for seller
bank_token_response = ZaiPayment.token_auths.generate(
  user_id: seller.data['users']['id'],
  token_type: "bank"
)

# Send bank_token to frontend, collect bank details, get bank_account_id

# 4. Create item for payment
item = ZaiPayment.items.create(
  name: "Product Purchase",
  amount: 10000, # $100.00
  payment_type: 2, # Credit card
  buyer_id: buyer.data['users']['id'],
  seller_id: seller.data['users']['id']
)

# 5. Process payment using card_account_id
# (Use Items Actions API or Payment API - to be implemented)
```

## Error Handling

### Common Errors

```ruby
begin
  response = ZaiPayment.token_auths.generate(
    user_id: user_id,
    token_type: token_type
  )
rescue ZaiPayment::Errors::ValidationError => e
  # Invalid user_id or token_type
  { error: "Validation error: #{e.message}", retryable: false }
rescue ZaiPayment::Errors::NotFoundError => e
  # User not found
  { error: "User not found: #{user_id}", retryable: false }
rescue ZaiPayment::Errors::UnauthorizedError => e
  # Authentication failed
  { error: "Authentication failed", retryable: false }
rescue ZaiPayment::Errors::RateLimitError => e
  # Rate limit exceeded
  { error: "Rate limit exceeded", retryable: true, retry_after: 60 }
rescue ZaiPayment::Errors::ServerError => e
  # Server error (5xx)
  { error: "Server error", retryable: true }
rescue ZaiPayment::Errors::TimeoutError => e
  # Request timeout
  { error: "Timeout", retryable: true }
end
```

### Validation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `user_id is required and cannot be blank` | Missing or empty user_id | Provide a valid user ID |
| `token_type must be one of: bank, card` | Invalid token_type | Use 'bank' or 'card' |
| `User not found` | User doesn't exist | Create user first |

## Best Practices

### 1. Token Lifecycle Management

```ruby
class TokenManager
  def initialize(user_id)
    @user_id = user_id
    @cache = {}
  end
  
  def get_token(type)
    cache_key = "#{@user_id}_#{type}"
    
    # Don't reuse expired tokens
    if @cache[cache_key] && !token_expired?(@cache[cache_key][:expires_at])
      return @cache[cache_key][:token]
    end
    
    # Generate fresh token
    response = ZaiPayment.token_auths.generate(
      user_id: @user_id,
      token_type: type
    )
    
    token_data = response.data['token_auth']
    
    @cache[cache_key] = {
      token: token_data['token'],
      expires_at: Time.parse(token_data['expires_at'])
    }
    
    token_data['token']
  end
  
  private
  
  def token_expired?(expires_at)
    # Consider expired 5 minutes before actual expiry
    expires_at < Time.now + 300
  end
end
```

### 2. Audit Logging

```ruby
def generate_token_with_audit(user_id:, token_type:, context: {})
  start_time = Time.now
  
  begin
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: token_type
    )
    
    log_event(
      event: 'token_generated',
      user_id: user_id,
      token_type: token_type,
      success: true,
      duration: Time.now - start_time,
      context: context
    )
    
    response
  rescue => e
    log_event(
      event: 'token_generation_failed',
      user_id: user_id,
      token_type: token_type,
      success: false,
      error: e.message,
      duration: Time.now - start_time,
      context: context
    )
    
    raise
  end
end
```

### 3. Rate Limiting

```ruby
class RateLimitedTokenGenerator
  def initialize(user_id)
    @user_id = user_id
    @redis = Redis.new
  end
  
  def generate(token_type:, limit: 10, window: 3600)
    rate_limit_key = "token_gen:#{@user_id}:#{Time.now.to_i / window}"
    current_count = @redis.incr(rate_limit_key)
    @redis.expire(rate_limit_key, window)
    
    if current_count > limit
      raise "Rate limit exceeded: #{limit} tokens per #{window} seconds"
    end
    
    ZaiPayment.token_auths.generate(
      user_id: @user_id,
      token_type: token_type
    )
  end
end
```

### 4. Retry Logic

```ruby
def generate_token_with_retry(user_id, token_type, max_retries: 3)
  retries = 0
  
  begin
    ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: token_type
    )
  rescue ZaiPayment::Errors::RateLimitError, 
         ZaiPayment::Errors::ServerError,
         ZaiPayment::Errors::TimeoutError => e
    retries += 1
    
    if retries < max_retries
      sleep_time = 2 ** retries # Exponential backoff
      sleep(sleep_time)
      retry
    else
      raise
    end
  end
end
```

## API Reference

For complete API documentation, see:
- [Zai: Generate Token API Reference](https://developer.hellozai.com/reference/generatetoken)
- [Token Auth Examples](../examples/token_auths.md)

## Related Resources

- [User Management](users.md) - Create users before generating tokens
- [Item Management](items.md) - Use payment accounts to create items
- [PromisePay.js Documentation](https://developer.hellozai.com/docs/promisepay-js)

