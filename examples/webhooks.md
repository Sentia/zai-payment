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

## Webhook Security: Complete Setup Guide

### Step 1: Generate and Register a Secret Key

Before setting up webhooks, you should establish a secure secret key for signature verification:

```ruby
require 'securerandom'

# Generate a cryptographically secure secret key (minimum 32 bytes)
secret_key = SecureRandom.alphanumeric(32)
# Example output: "aB3xYz9mKpQrTuVwXy2zAbCdEfGhIjKl"

# Store this in your environment variables or secure vault
# NEVER commit this to version control!
puts "Add this to your environment variables:"
puts "ZAI_WEBHOOK_SECRET=#{secret_key}"

# Register the secret key with Zai
response = ZaiPayment.webhooks.create_secret_key(secret_key: secret_key)

if response.success?
  puts "✅ Secret key registered successfully with Zai!"
  puts "Store this key securely - you'll need it to verify webhook signatures"
else
  puts "❌ Failed to register secret key"
end
```

### Step 2: Create a Webhook

Now create a webhook to receive notifications:

```ruby
response = ZaiPayment.webhooks.create(
  url: 'https://your-app.com/webhooks/zai',
  object_type: 'transactions',
  enabled: true,
  description: 'Production webhook for transaction updates'
)

webhook = response.data
puts "Created webhook: #{webhook['id']}"
```

### Step 3: Implement Webhook Endpoint

Here's a complete Rails controller example with signature verification:

```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  # Skip CSRF token verification for webhook endpoints
  skip_before_action :verify_authenticity_token
  
  # Add basic rate limiting (if using Rack::Attack or similar)
  # throttle('webhooks/ip', limit: 100, period: 1.minute)

  def zai_webhook
    # Read the raw request body - IMPORTANT: Don't parse it first!
    payload = request.body.read
    signature_header = request.headers['Webhooks-signature']
    secret_key = ENV['ZAI_WEBHOOK_SECRET']

    # Verify the signature
    unless verify_webhook_signature(payload, signature_header, secret_key)
      Rails.logger.warn "Invalid webhook signature received from #{request.remote_ip}"
      return render json: { error: 'Invalid signature' }, status: :unauthorized
    end

    # Parse and process the webhook
    webhook_data = JSON.parse(payload)
    process_webhook(webhook_data)
    
    # Return 200 to acknowledge receipt
    render json: { status: 'success' }, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid JSON in webhook: #{e.message}"
    render json: { error: 'Invalid JSON' }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "Webhook processing error: #{e.message}"
    render json: { error: 'Processing error' }, status: :internal_server_error
  end

  private

  def verify_webhook_signature(payload, signature_header, secret_key)
    return false if signature_header.blank?

    ZaiPayment.webhooks.verify_signature(
      payload: payload,
      signature_header: signature_header,
      secret_key: secret_key,
      tolerance: 300 # 5 minutes - adjust based on your needs
    )
  rescue ZaiPayment::Errors::ValidationError => e
    Rails.logger.warn "Webhook signature validation failed: #{e.message}"
    false
  end

  def process_webhook(data)
    # Log the webhook for debugging
    Rails.logger.info "Processing Zai webhook: #{data['event']}"
    
    # Handle different webhook events
    case data['event']
    when 'transaction.created'
      handle_transaction_created(data)
    when 'transaction.updated'
      handle_transaction_updated(data)
    when 'transaction.completed'
      handle_transaction_completed(data)
    else
      Rails.logger.info "Unhandled webhook event: #{data['event']}"
    end
  end

  def handle_transaction_created(data)
    # Your logic here
    Rails.logger.info "Transaction created: #{data['transaction']['id']}"
  end

  def handle_transaction_updated(data)
    # Your logic here
    Rails.logger.info "Transaction updated: #{data['transaction']['id']}"
  end

  def handle_transaction_completed(data)
    # Your logic here
    Rails.logger.info "Transaction completed: #{data['transaction']['id']}"
  end
end
```

### Step 4: Configure Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Webhook endpoint
  post '/webhooks/zai', to: 'webhooks#zai_webhook'
end
```

### Step 5: Test Your Webhook

Create a test to verify your implementation:

```ruby
# spec/controllers/webhooks_controller_spec.rb
require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do
  let(:secret_key) { SecureRandom.alphanumeric(32) }
  let(:webhook_payload) do
    {
      event: 'transaction.updated',
      transaction: {
        id: 'txn_123',
        state: 'completed',
        amount: 1000
      }
    }.to_json
  end

  before do
    ENV['ZAI_WEBHOOK_SECRET'] = secret_key
  end

  describe 'POST #zai_webhook' do
    context 'with valid signature' do
      it 'processes the webhook successfully' do
        timestamp = Time.now.to_i
        signature = ZaiPayment::Resources::Webhook.new.generate_signature(
          webhook_payload, secret_key, timestamp
        )
        
        request.headers['Webhooks-signature'] = "t=#{timestamp},v=#{signature}"
        post :zai_webhook, body: webhook_payload
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('success')
      end
    end

    context 'with invalid signature' do
      it 'rejects the webhook' do
        timestamp = Time.now.to_i
        request.headers['Webhooks-signature'] = "t=#{timestamp},v=invalid_signature"
        post :zai_webhook, body: webhook_payload
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with missing signature header' do
      it 'rejects the webhook' do
        post :zai_webhook, body: webhook_payload
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with expired timestamp' do
      it 'rejects old webhooks to prevent replay attacks' do
        old_timestamp = Time.now.to_i - 600 # 10 minutes ago
        signature = ZaiPayment::Resources::Webhook.new.generate_signature(
          webhook_payload, secret_key, old_timestamp
        )
        
        request.headers['Webhooks-signature'] = "t=#{old_timestamp},v=#{signature}"
        post :zai_webhook, body: webhook_payload
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

## Basic Webhook Operations

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

## Additional Webhook Security Examples

### Generate Signature for Testing

You can generate signatures for testing your webhook implementation:

```ruby
# Useful for integration tests or webhook simulation
payload = '{"event": "transaction.updated", "id": "txn_123"}'
secret_key = ENV['ZAI_WEBHOOK_SECRET']
timestamp = Time.now.to_i

webhook = ZaiPayment::Resources::Webhook.new
signature = webhook.generate_signature(payload, secret_key, timestamp)

puts "Signature header: t=#{timestamp},v=#{signature}"
```

### Verify Signature Manually

If you need more control over the verification process:

```ruby
webhook = ZaiPayment::Resources::Webhook.new

begin
  is_valid = webhook.verify_signature(
    payload: request_body,
    signature_header: request.headers['Webhooks-signature'],
    secret_key: ENV['ZAI_WEBHOOK_SECRET'],
    tolerance: 300
  )
  
  if is_valid
    puts "✅ Webhook signature is valid"
  else
    puts "❌ Webhook signature is invalid"
  end
rescue ZaiPayment::Errors::ValidationError => e
  puts "⚠️ Validation error: #{e.message}"
end
```

### Sinatra Example

If you're using Sinatra instead of Rails:

```ruby
require 'sinatra'
require 'json'
require 'zai_payment'

# Configure ZaiPayment
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end

post '/webhooks/zai' do
  # Read raw request body
  payload = request.body.read
  signature_header = request.env['HTTP_WEBHOOKS_SIGNATURE']
  secret_key = ENV['ZAI_WEBHOOK_SECRET']
  
  # Verify signature
  webhook = ZaiPayment::Resources::Webhook.new
  
  begin
    unless webhook.verify_signature(
      payload: payload,
      signature_header: signature_header,
      secret_key: secret_key
    )
      halt 401, { error: 'Invalid signature' }.to_json
    end
    
    # Process webhook
    data = JSON.parse(payload)
    logger.info "Received webhook: #{data['event']}"
    
    # Your processing logic here
    
    status 200
    { status: 'success' }.to_json
  rescue ZaiPayment::Errors::ValidationError => e
    logger.error "Webhook validation failed: #{e.message}"
    halt 401, { error: e.message }.to_json
  rescue StandardError => e
    logger.error "Webhook processing error: #{e.message}"
    halt 500, { error: 'Processing error' }.to_json
  end
end
```

### Rack Middleware Example

Create reusable middleware for webhook verification:

```ruby
# lib/middleware/zai_webhook_verifier.rb
module Middleware
  class ZaiWebhookVerifier
    def initialize(app, options = {})
      @app = app
      @secret_key = options[:secret_key] || ENV['ZAI_WEBHOOK_SECRET']
      @tolerance = options[:tolerance] || 300
      @webhook_path = options[:path] || '/webhooks/zai'
    end

    def call(env)
      request = Rack::Request.new(env)
      
      # Only verify requests to the webhook path
      if request.path == @webhook_path && request.post?
        unless verify_request(request)
          return [401, { 'Content-Type' => 'application/json' }, 
                  [{ error: 'Invalid webhook signature' }.to_json]]
        end
      end
      
      @app.call(env)
    end

    private

    def verify_request(request)
      body = request.body.read
      request.body.rewind # Important: rewind for downstream processing
      
      signature_header = request.env['HTTP_WEBHOOKS_SIGNATURE']
      return false unless signature_header
      
      webhook = ZaiPayment::Resources::Webhook.new
      webhook.verify_signature(
        payload: body,
        signature_header: signature_header,
        secret_key: @secret_key,
        tolerance: @tolerance
      )
    rescue ZaiPayment::Errors::ValidationError
      false
    end
  end
end

# Usage in config.ru or Rails application.rb:
use Middleware::ZaiWebhookVerifier, 
    secret_key: ENV['ZAI_WEBHOOK_SECRET'],
    tolerance: 300,
    path: '/webhooks/zai'
```

### Background Job Processing

For production systems, process webhooks asynchronously:

```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def zai_webhook
    payload = request.body.read
    signature_header = request.headers['Webhooks-signature']
    
    # Quick verification
    unless verify_signature(payload, signature_header)
      return render json: { error: 'Invalid signature' }, status: :unauthorized
    end
    
    # Enqueue for background processing
    ZaiWebhookJob.perform_later(payload)
    
    # Return immediately
    render json: { status: 'accepted' }, status: :accepted
  end

  private

  def verify_signature(payload, signature_header)
    ZaiPayment.webhooks.verify_signature(
      payload: payload,
      signature_header: signature_header,
      secret_key: ENV['ZAI_WEBHOOK_SECRET']
    )
  rescue ZaiPayment::Errors::ValidationError
    false
  end
end

# app/jobs/zai_webhook_job.rb
class ZaiWebhookJob < ApplicationJob
  queue_as :webhooks
  
  # Retry logic for transient failures
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(payload)
    data = JSON.parse(payload)
    
    # Idempotent processing - check if already processed
    return if WebhookEvent.exists?(external_id: data['id'])
    
    # Process the webhook
    WebhookEvent.create!(
      external_id: data['id'],
      event_type: data['event'],
      payload: data,
      processed_at: Time.current
    )
    
    # Handle event
    case data['event']
    when 'transaction.completed'
      TransactionProcessor.process_completion(data['transaction'])
    when 'transaction.failed'
      TransactionProcessor.process_failure(data['transaction'])
    end
  end
end
```

### Idempotency Pattern

Ensure webhooks are processed only once:

```ruby
# app/models/webhook_event.rb
class WebhookEvent < ApplicationRecord
  # Columns: external_id, event_type, payload (jsonb), processed_at, created_at
  
  validates :external_id, presence: true, uniqueness: true
  
  def self.process_if_new(webhook_data)
    # Use database constraint to ensure atomicity
    transaction do
      event = create!(
        external_id: webhook_data['id'],
        event_type: webhook_data['event'],
        payload: webhook_data
      )
      
      yield event if block_given?
      
      event.update!(processed_at: Time.current)
    end
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info "Webhook already processed: #{webhook_data['id']}"
    false
  end
end

# Usage:
def process_webhook(data)
  WebhookEvent.process_if_new(data) do |event|
    # Your processing logic here
    # This block only runs if the webhook is new
    case event.event_type
    when 'transaction.completed'
      handle_completion(data)
    end
  end
end
```

