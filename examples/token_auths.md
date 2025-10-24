# Token Auth Examples

This file contains practical examples of using the TokenAuth resource to generate tokens for bank or card accounts.

## Table of Contents
- [Basic Usage](#basic-usage)
- [Bank Tokens](#bank-tokens)
- [Card Tokens](#card-tokens)
- [Integration Examples](#integration-examples)
- [Error Handling](#error-handling)
- [Security Best Practices](#security-best-practices)

## Basic Usage

### Generate a Bank Token (Default)

```ruby
# Generate a bank token (default token_type)
response = ZaiPayment.token_auths.generate(
  user_id: "seller-68611249"
)

puts response.data
# => {
#   "token_auth" => {
#     "token" => "tok_bank_abc123...",
#     "user_id" => "seller-68611249",
#     "token_type" => "bank",
#     "created_at" => "2025-10-24T12:00:00Z",
#     "expires_at" => "2025-10-24T13:00:00Z"
#   }
# }

token = response.data['token_auth']['token']
```

### Generate with Explicit Token Type

```ruby
# Generate a bank token (explicit)
response = ZaiPayment.token_auths.generate(
  user_id: "seller-68611249",
  token_type: "bank"
)

# Generate a card token (explicit)
response = ZaiPayment.token_auths.generate(
  user_id: "buyer-12345",
  token_type: "card"
)
```

## Bank Tokens

Bank tokens are used for securely collecting bank account information from users.

### Example: Collect Bank Account Details

```ruby
# Step 1: Create a payout user (seller)
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

# Step 2: Generate a bank token for the seller
token_response = ZaiPayment.token_auths.generate(
  user_id: seller_id,
  token_type: "bank"
)

bank_token = token_response.data['token_auth']['token']

# Step 3: Use this token with PromisePay.js on the frontend
# to securely collect bank account details
puts "Bank Token: #{bank_token}"
puts "Send this token to your frontend to use with PromisePay.js"
```

### Example: Multiple Bank Accounts

```ruby
# Generate tokens for multiple sellers to collect their bank account details
sellers = ["seller-001", "seller-002", "seller-003"]

bank_tokens = sellers.map do |seller_id|
  response = ZaiPayment.token_auths.generate(
    user_id: seller_id,
    token_type: "bank"
  )
  
  {
    seller_id: seller_id,
    token: response.data['token_auth']['token'],
    expires_at: response.data['token_auth']['expires_at']
  }
end

puts bank_tokens
```

## Card Tokens

Card tokens are used for securely collecting credit card information from buyers.

### Example: Collect Card Details for Payment

```ruby
# Step 1: Create a payin user (buyer)
buyer = ZaiPayment.users.create(
  user_type: "payin",
  email: "buyer@example.com",
  first_name: "John",
  last_name: "Doe",
  country: "USA"
)

buyer_id = buyer.data['users']['id']

# Step 2: Generate a card token for the buyer
token_response = ZaiPayment.token_auths.generate(
  user_id: buyer_id,
  token_type: "card"
)

card_token = token_response.data['token_auth']['token']

# Step 3: Use this token with PromisePay.js on the frontend
# to securely collect credit card details
puts "Card Token: #{card_token}"
puts "Send this token to your frontend to use with PromisePay.js"
```

### Example: Card Token for Checkout Flow

```ruby
# In a checkout flow, generate a card token for the buyer
def generate_card_token_for_checkout(buyer_id)
  response = ZaiPayment.token_auths.generate(
    user_id: buyer_id,
    token_type: "card"
  )
  
  token_data = response.data['token_auth']
  
  {
    token: token_data['token'],
    expires_at: token_data['expires_at'],
    # Send this to your frontend
    frontend_data: {
      token: token_data['token'],
      user_id: buyer_id
    }
  }
end

# Usage
checkout_data = generate_card_token_for_checkout("buyer-12345")
puts checkout_data[:frontend_data].to_json
```

## Integration Examples

### Example: Rails Controller Integration

```ruby
# app/controllers/payment_tokens_controller.rb
class PaymentTokensController < ApplicationController
  before_action :authenticate_user!
  
  # POST /payment_tokens/bank
  def create_bank_token
    user_id = current_user.zai_seller_id
    
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: "bank"
    )
    
    render json: {
      token: response.data['token_auth']['token'],
      expires_at: response.data['token_auth']['expires_at']
    }
  rescue ZaiPayment::Errors::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ZaiPayment::Errors::ApiError => e
    render json: { error: "Failed to generate token" }, status: :bad_gateway
  end
  
  # POST /payment_tokens/card
  def create_card_token
    user_id = current_user.zai_buyer_id
    
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: "card"
    )
    
    render json: {
      token: response.data['token_auth']['token'],
      expires_at: response.data['token_auth']['expires_at']
    }
  rescue ZaiPayment::Errors::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ZaiPayment::Errors::ApiError => e
    render json: { error: "Failed to generate token" }, status: :bad_gateway
  end
end
```

### Example: Service Object Pattern

```ruby
# app/services/token_generator_service.rb
class TokenGeneratorService
  def initialize(user_id)
    @user_id = user_id
  end
  
  def generate_bank_token
    generate_token(type: 'bank')
  end
  
  def generate_card_token
    generate_token(type: 'card')
  end
  
  private
  
  def generate_token(type:)
    response = ZaiPayment.token_auths.generate(
      user_id: @user_id,
      token_type: type
    )
    
    token_data = response.data['token_auth']
    
    {
      success: true,
      token: token_data['token'],
      expires_at: token_data['expires_at'],
      type: type
    }
  rescue ZaiPayment::Errors::ValidationError => e
    {
      success: false,
      error: e.message,
      type: :validation_error
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      error: "API error: #{e.message}",
      type: :api_error
    }
  end
end

# Usage
service = TokenGeneratorService.new("seller-123")
result = service.generate_bank_token

if result[:success]
  puts "Token: #{result[:token]}"
else
  puts "Error: #{result[:error]}"
end
```

### Example: Frontend Integration

```ruby
# Backend: Generate and send token to frontend
def generate_frontend_token(user_id, token_type)
  response = ZaiPayment.token_auths.generate(
    user_id: user_id,
    token_type: token_type
  )
  
  token_data = response.data['token_auth']
  
  # Return data formatted for frontend
  {
    token: token_data['token'],
    expiresAt: token_data['expires_at'],
    userId: user_id,
    tokenType: token_type
  }
end

# Frontend JavaScript (example)
# <script src="https://cdn.assemblypay.com/promisepay.js"></script>
# <script>
#   // Receive token from backend
#   fetch('/api/payment_tokens/card', { method: 'POST' })
#     .then(res => res.json())
#     .then(data => {
#       // Use the token with PromisePay.js
#       PromisePay.setToken(data.token);
#       
#       // Collect card details
#       PromisePay.createCardAccount({
#         card_number: '4111111111111111',
#         expiry_month: '12',
#         expiry_year: '2025',
#         cvv: '123'
#       }, function(response) {
#         console.log('Card account created:', response);
#       });
#     });
# </script>
```

## Error Handling

### Example: Comprehensive Error Handling

```ruby
def generate_token_with_error_handling(user_id, token_type)
  begin
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: token_type
    )
    
    {
      success: true,
      token: response.data['token_auth']['token'],
      expires_at: response.data['token_auth']['expires_at']
    }
  rescue ZaiPayment::Errors::ValidationError => e
    # Invalid parameters (user_id or token_type)
    {
      success: false,
      error: e.message,
      error_type: :validation,
      retryable: false
    }
  rescue ZaiPayment::Errors::UnauthorizedError => e
    # Authentication failed
    {
      success: false,
      error: "Authentication failed",
      error_type: :auth,
      retryable: false
    }
  rescue ZaiPayment::Errors::NotFoundError => e
    # User not found
    {
      success: false,
      error: "User not found: #{user_id}",
      error_type: :not_found,
      retryable: false
    }
  rescue ZaiPayment::Errors::RateLimitError => e
    # Rate limit exceeded
    {
      success: false,
      error: "Rate limit exceeded",
      error_type: :rate_limit,
      retryable: true,
      retry_after: 60 # seconds
    }
  rescue ZaiPayment::Errors::ServerError => e
    # Server error (5xx)
    {
      success: false,
      error: "Server error",
      error_type: :server,
      retryable: true
    }
  rescue ZaiPayment::Errors::TimeoutError => e
    # Request timeout
    {
      success: false,
      error: "Request timeout",
      error_type: :timeout,
      retryable: true
    }
  rescue ZaiPayment::Errors::ApiError => e
    # Generic API error
    {
      success: false,
      error: e.message,
      error_type: :api,
      retryable: false
    }
  end
end

# Usage
result = generate_token_with_error_handling("buyer-123", "card")

if result[:success]
  puts "Token: #{result[:token]}"
else
  puts "Error: #{result[:error]}"
  puts "Retryable: #{result[:retryable]}" if result[:retryable]
end
```

### Example: Retry Logic

```ruby
def generate_token_with_retry(user_id, token_type, max_retries: 3)
  retries = 0
  
  begin
    response = ZaiPayment.token_auths.generate(
      user_id: user_id,
      token_type: token_type
    )
    
    response.data['token_auth']['token']
  rescue ZaiPayment::Errors::RateLimitError, 
         ZaiPayment::Errors::ServerError,
         ZaiPayment::Errors::TimeoutError => e
    retries += 1
    
    if retries < max_retries
      sleep_time = 2 ** retries # Exponential backoff: 2, 4, 8 seconds
      puts "Retry #{retries}/#{max_retries} after #{sleep_time}s..."
      sleep(sleep_time)
      retry
    else
      puts "Max retries reached"
      raise
    end
  end
end

# Usage
begin
  token = generate_token_with_retry("buyer-123", "card")
  puts "Token: #{token}"
rescue => e
  puts "Failed after retries: #{e.message}"
end
```

## Security Best Practices

### Example: Token Expiry Management

```ruby
class TokenManager
  def initialize(user_id)
    @user_id = user_id
    @cache = {}
  end
  
  def get_bank_token
    get_token('bank')
  end
  
  def get_card_token
    get_token('card')
  end
  
  private
  
  def get_token(type)
    cache_key = "#{@user_id}_#{type}"
    
    # Check if we have a valid cached token
    if @cache[cache_key] && !token_expired?(@cache[cache_key][:expires_at])
      return @cache[cache_key][:token]
    end
    
    # Generate new token
    response = ZaiPayment.token_auths.generate(
      user_id: @user_id,
      token_type: type
    )
    
    token_data = response.data['token_auth']
    
    # Cache the token
    @cache[cache_key] = {
      token: token_data['token'],
      expires_at: Time.parse(token_data['expires_at'])
    }
    
    token_data['token']
  end
  
  def token_expired?(expires_at)
    # Consider token expired 5 minutes before actual expiry
    expires_at < Time.now + 300
  end
end

# Usage
manager = TokenManager.new("buyer-123")
token = manager.get_card_token  # Generates new token
token2 = manager.get_card_token # Returns cached token if not expired
```

### Example: Audit Logging

```ruby
class AuditedTokenGenerator
  def self.generate(user_id:, token_type:, request_context: {})
    start_time = Time.now
    
    begin
      response = ZaiPayment.token_auths.generate(
        user_id: user_id,
        token_type: token_type
      )
      
      # Log successful generation
      log_token_generation(
        user_id: user_id,
        token_type: token_type,
        success: true,
        duration: Time.now - start_time,
        context: request_context
      )
      
      response
    rescue => e
      # Log failed generation
      log_token_generation(
        user_id: user_id,
        token_type: token_type,
        success: false,
        error: e.message,
        duration: Time.now - start_time,
        context: request_context
      )
      
      raise
    end
  end
  
  def self.log_token_generation(data)
    Rails.logger.info({
      event: 'token_generation',
      timestamp: Time.now.iso8601,
      **data
    }.to_json)
    
    # Optionally store in database for audit trail
    # AuditLog.create!(
    #   event_type: 'token_generation',
    #   user_id: data[:user_id],
    #   success: data[:success],
    #   metadata: data
    # )
  end
end

# Usage
response = AuditedTokenGenerator.generate(
  user_id: "buyer-123",
  token_type: "card",
  request_context: {
    ip_address: request.ip,
    user_agent: request.user_agent,
    session_id: session.id
  }
)
```

### Example: Rate Limiting Protection

```ruby
class RateLimitedTokenGenerator
  def initialize(user_id)
    @user_id = user_id
    @redis = Redis.new
  end
  
  def generate(token_type:, limit: 10, window: 3600)
    # Check rate limit
    rate_limit_key = "token_gen:#{@user_id}:#{Time.now.to_i / window}"
    current_count = @redis.incr(rate_limit_key)
    @redis.expire(rate_limit_key, window)
    
    if current_count > limit
      raise "Rate limit exceeded: #{limit} tokens per #{window} seconds"
    end
    
    # Generate token
    response = ZaiPayment.token_auths.generate(
      user_id: @user_id,
      token_type: token_type
    )
    
    response.data['token_auth']['token']
  end
end

# Usage
generator = RateLimitedTokenGenerator.new("buyer-123")
token = generator.generate(token_type: "card", limit: 5, window: 3600)
```

## Complete Example: Payment Flow

```ruby
# Complete example showing the full payment flow with token generation

class PaymentFlowService
  def initialize(buyer_id, seller_id)
    @buyer_id = buyer_id
    @seller_id = seller_id
  end
  
  def process_payment(amount:, payment_method: :card)
    # Step 1: Generate token for buyer to collect payment details
    token_response = generate_payment_token(payment_method)
    
    # Step 2: Return token to frontend for secure data collection
    # (In real app, frontend would use PromisePay.js to collect details)
    
    # Step 3: Create item for payment
    item_response = create_payment_item(amount)
    
    {
      success: true,
      token: token_response[:token],
      item_id: item_response[:item_id],
      message: "Ready to process payment"
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end
  
  private
  
  def generate_payment_token(payment_method)
    token_type = payment_method == :card ? 'card' : 'bank'
    
    response = ZaiPayment.token_auths.generate(
      user_id: @buyer_id,
      token_type: token_type
    )
    
    {
      token: response.data['token_auth']['token'],
      expires_at: response.data['token_auth']['expires_at']
    }
  end
  
  def create_payment_item(amount)
    response = ZaiPayment.items.create(
      name: "Payment Transaction",
      amount: amount,
      payment_type: 2, # Credit card
      buyer_id: @buyer_id,
      seller_id: @seller_id
    )
    
    {
      item_id: response.data['items']['id']
    }
  end
end

# Usage
service = PaymentFlowService.new("buyer-123", "seller-456")
result = service.process_payment(amount: 10000) # $100.00

if result[:success]
  puts "Payment token: #{result[:token]}"
  puts "Item ID: #{result[:item_id]}"
  puts "Send token to frontend for payment collection"
else
  puts "Error: #{result[:error]}"
end
```

