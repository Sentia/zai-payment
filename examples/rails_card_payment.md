# Rails Card Payment Example

This guide demonstrates how to implement a complete card payment workflow in a Rails application using the `zai_payment` gem.

## Table of Contents

1. [Setup](#setup)
2. [Configuration](#configuration)
3. [User Management](#user-management)
4. [Card Account Setup](#card-account-setup)
5. [Creating an Item](#creating-an-item)
6. [Making a Payment](#making-a-payment)
7. [Webhook Handling](#webhook-handling)
8. [Complete Flow Example](#complete-flow-example)
9. [Reference](#reference)

## Setup

Add the gem to your Gemfile:

```ruby
gem 'zai_payment'
```

Then run:

```bash
bundle install
```

## Configuration

Configure the gem in an initializer (`config/initializers/zai_payment.rb`):

```ruby
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.environment = Rails.env.production? ? 'production' : 'prelive'
end
```

## User Management

### Creating Users

```ruby
# In your controller or service object
class PaymentService
  def initialize
    @client = ZaiPayment::Client.new
  end

  # Create a buyer
  def create_buyer(email:, first_name:, last_name:, mobile:)
    response = @client.users.create(
      id: "buyer_#{SecureRandom.hex(8)}", # Your internal user ID
      first_name: first_name,
      last_name: last_name,
      email: email,
      mobile: mobile,
      country: 'AUS'
    )
    
    # Store zai_user_id in your database
    response.data['id']
  end

  # Create a seller
  def create_seller(email:, first_name:, last_name:, mobile:)
    response = @client.users.create(
      id: "seller_#{SecureRandom.hex(8)}",
      first_name: first_name,
      last_name: last_name,
      email: email,
      mobile: mobile,
      country: 'AUS'
    )
    
    response.data['id']
  end
end
```

### Example Controller

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create_zai_user
    service = PaymentService.new
    
    zai_user_id = service.create_buyer(
      email: current_user.email,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      mobile: current_user.phone
    )
    
    # Update your user record
    current_user.update(zai_user_id: zai_user_id)
    
    redirect_to dashboard_path, notice: 'User created successfully'
  rescue ZaiPayment::Errors::ApiError => e
    redirect_to dashboard_path, alert: "Error: #{e.message}"
  end
end
```

## Card Account Setup

### Generating a Card Auth Token

```ruby
# app/controllers/card_accounts_controller.rb
class CardAccountsController < ApplicationController
  def new
    # Generate a card auth token for the hosted form
    client = ZaiPayment::Client.new
    
    response = client.token_auths.create(
      token_type: 'card',
      user_id: current_user.zai_user_id
    )
    
    @card_token = response.data['token']
  end
end
```

### View with Hosted Form


```erb
<!-- app/views/card_accounts/new.html.erb -->
<div class="card-form-container">
  <h2>Add Your Card</h2>
  
  <div id="card-container"></div>
  
  <script src="https://hosted.assemblypay.com/assembly.js"></script>
  <script>
    let dropinHandler = DropIn.create({
      cardTokenAuth: '<%= @card_token %>',
      environment: '<%= Rails.env.production? ? 'production' : 'prelive' %>',
      targetElementId: '#card-container',
      cardAccountCreationCallback: function(cardAccountResult) {
        // Send the card account ID to your server
        fetch('/card_accounts', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify({
            card_account_id: cardAccountResult.id
          })
        })
        .then(response => response.json())
        .then(data => {
          alert("Card saved successfully!");
          window.location.href = '/payments/new';
        })
        .catch(error => {
          alert("Error saving card: " + error);
        });
      }
    }, function (error, instance) {
      if(error) {
        alert("Error: " + error);
      }
    });
  </script>
</div>
```

> **Note:** For more details on the Hosted Form integration, including PCI compliance, supported browsers, and error handling, see the [Zai Hosted Form Documentation](https://developer.hellozai.com/docs/integrating-drop-in-ui-for-capturing-a-credit-card).

### Storing Card Account ID

```ruby
# app/controllers/card_accounts_controller.rb
class CardAccountsController < ApplicationController
  def create
    # Store the card account ID returned from the hosted form
    current_user.update(
      zai_card_account_id: params[:card_account_id]
    )
    
    render json: { success: true }
  end
  
  # List user's card accounts
  def index
    client = ZaiPayment::Client.new
    
    response = client.card_accounts.list(
      user_id: current_user.zai_user_id
    )
    
    @card_accounts = response.data['card_accounts']
  end
end
```

## Creating an Item

```ruby
# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  def create
    client = ZaiPayment::Client.new
    
    # Assuming you have a transaction/order model
    transaction = current_user.transactions.create!(
      amount: params[:amount],
      seller_id: params[:seller_id],
      description: params[:description]
    )
    
    # Create item in Zai
    response = client.items.create(
      id: "order_#{transaction.id}", # Your internal order ID
      name: params[:description],
      amount: (params[:amount].to_f * 100).to_i, # Convert to cents
      payment_type: 1, # 1 = Payin
      buyer_id: current_user.zai_user_id,
      seller_id: User.find(params[:seller_id]).zai_user_id,
      fee_ids: '', # Optional: platform fees
      description: params[:description]
    )
    
    zai_item_id = response.data['id']
    transaction.update(zai_item_id: zai_item_id)
    
    redirect_to payment_path(transaction), notice: 'Ready to make payment'
  rescue ZaiPayment::Errors::ApiError => e
    redirect_to new_item_path, alert: "Error: #{e.message}"
  end
end
```

## Making a Payment

### Payment Controller

```ruby
# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  def show
    @transaction = current_user.transactions.find(params[:id])
    @card_accounts = fetch_card_accounts
  end
  
  def create
    transaction = current_user.transactions.find(params[:transaction_id])
    client = ZaiPayment::Client.new
    
    # Make payment using card account
    response = client.items.make_payment(
      id: transaction.zai_item_id,
      account_id: params[:card_account_id] # The card account ID
    )
    
    transaction.update(
      status: 'processing',
      zai_transaction_id: response.data.dig('transactions', 0, 'id')
    )
    
    redirect_to transaction_path(transaction), 
                notice: 'Payment initiated successfully. You will be notified once completed.'
  rescue ZaiPayment::Errors::ApiError => e
    redirect_to payment_path(transaction), alert: "Payment failed: #{e.message}"
  end
  
  private
  
  def fetch_card_accounts
    client = ZaiPayment::Client.new
    response = client.card_accounts.list(user_id: current_user.zai_user_id)
    response.data['card_accounts'] || []
  end
end
```

### Payment View

```erb
<!-- app/views/payments/show.html.erb -->
<div class="payment-page">
  <h2>Complete Payment</h2>
  
  <div class="transaction-details">
    <p><strong>Amount:</strong> <%= number_to_currency(@transaction.amount) %></p>
    <p><strong>Description:</strong> <%= @transaction.description %></p>
    <p><strong>Seller:</strong> <%= @transaction.seller.name %></p>
  </div>
  
  <%= form_with url: payments_path, method: :post do |f| %>
    <%= f.hidden_field :transaction_id, value: @transaction.id %>
    
    <div class="form-group">
      <%= f.label :card_account_id, "Select Card" %>
      <%= f.select :card_account_id, 
          options_for_select(@card_accounts.map { |ca| 
            ["#{ca['card']['type']} ending in #{ca['card']['number']}", ca['id']] 
          }), 
          { include_blank: 'Choose a card' },
          class: 'form-control' %>
    </div>
    
    <div class="actions">
      <%= f.submit "Pay #{number_to_currency(@transaction.amount)}", 
          class: 'btn btn-primary' %>
      <%= link_to 'Add New Card', new_card_account_path, 
          class: 'btn btn-secondary' %>
    </div>
  <% end %>
</div>
```

## Webhook Handling

### Setting Up Webhooks

```ruby
# One-time setup (can be done in Rails console or a rake task)
# lib/tasks/zai_setup.rake

namespace :zai do
  desc "Setup Zai webhooks"
  task setup_webhooks: :environment do
    client = ZaiPayment::Client.new
    
    # Item status changes
    client.webhooks.create(
      object_type: 'items',
      url: "#{ENV['APP_URL']}/webhooks/zai/items"
    )
    
    # Transaction events
    client.webhooks.create(
      object_type: 'transactions',
      url: "#{ENV['APP_URL']}/webhooks/zai/transactions"
    )
    
    # Batch transaction events (settlement)
    client.webhooks.create(
      object_type: 'batch_transactions',
      url: "#{ENV['APP_URL']}/webhooks/zai/batch_transactions"
    )
    
    puts "Webhooks configured successfully!"
  end
end
```

### Webhook Controller

```ruby
# app/controllers/webhooks/zai_controller.rb
module Webhooks
  class ZaiController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_signature
    
    # Handle item status changes
    def items
      payload = JSON.parse(request.body.read)
      
      # Item completed
      if payload['status'] == 'completed'
        item_id = payload['id']
        transaction = Transaction.find_by(zai_item_id: item_id)
        
        if transaction
          transaction.update(
            status: 'completed',
            released_amount: payload['released_amount']
          )
          
          # Notify user
          PaymentMailer.payment_completed(transaction).deliver_later
        end
      end
      
      head :ok
    end
    
    # Handle transaction events (card authorized)
    def transactions
      payload = JSON.parse(request.body.read)
      
      if payload['type'] == 'payment' && payload['type_method'] == 'credit_card'
        transaction = Transaction.find_by(zai_transaction_id: payload['id'])
        
        if transaction
          if payload['status'] == 'successful'
            transaction.update(status: 'authorized')
            # Notify user
            PaymentMailer.payment_authorized(transaction).deliver_later
          elsif payload['status'] == 'failed'
            transaction.update(status: 'failed', failure_reason: payload['failure_reason'])
            PaymentMailer.payment_failed(transaction).deliver_later
          end
        end
      end
      
      head :ok
    end
    
    # Handle batch transactions (funds settled)
    def batch_transactions
      payload = JSON.parse(request.body.read)
      
      if payload['type'] == 'payment_funding' && 
         payload['type_method'] == 'credit_card' &&
         payload['status'] == 'successful'
        
        # Find related item and mark as settled
        batch_id = payload['id']
        transaction = Transaction.find_by(zai_batch_transaction_id: batch_id)
        
        if transaction
          transaction.update(status: 'settled')
          # Funds are now in seller's wallet
          PaymentMailer.payment_settled(transaction).deliver_later
        end
      end
      
      head :ok
    end
    
    private
    
    def verify_webhook_signature
      # Verify the webhook signature using the gem's helper
      signature = request.headers['X-Webhook-Signature']
      
      unless ZaiPayment::Webhook.verify_signature?(
        payload: request.body.read,
        signature: signature,
        secret: ENV['ZAI_WEBHOOK_SECRET']
      )
        head :unauthorized
      end
    end
  end
end
```

### Routes for Webhooks

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :webhooks do
    post 'zai/items', to: 'zai#items'
    post 'zai/transactions', to: 'zai#transactions'
    post 'zai/batch_transactions', to: 'zai#batch_transactions'
  end
end
```

## Complete Flow Example

### Service Object for Complete Payment Flow

```ruby
# app/services/card_payment_flow.rb
class CardPaymentFlow
  attr_reader :client, :errors
  
  def initialize
    @client = ZaiPayment::Client.new
    @errors = []
  end
  
  # Complete flow from creating users to payment
  def execute(buyer_params:, seller_params:, payment_params:)
    ActiveRecord::Base.transaction do
      # Step 1: Create or get buyer
      buyer_id = ensure_zai_user(buyer_params)
      return false unless buyer_id
      
      # Step 2: Create or get seller
      seller_id = ensure_zai_user(seller_params)
      return false unless seller_id
      
      # Step 3: Create item
      item_id = create_item(
        buyer_id: buyer_id,
        seller_id: seller_id,
        amount: payment_params[:amount],
        description: payment_params[:description]
      )
      return false unless item_id
      
      # Step 4: Make payment
      make_payment(
        item_id: item_id,
        card_account_id: payment_params[:card_account_id]
      )
    end
  rescue ZaiPayment::Errors::ApiError => e
    @errors << e.message
    false
  end
  
  private
  
  def ensure_zai_user(user_params)
    # Check if user already exists in Zai
    return user_params[:zai_user_id] if user_params[:zai_user_id].present?
    
    # Create new user
    response = @client.users.create(
      id: user_params[:id],
      first_name: user_params[:first_name],
      last_name: user_params[:last_name],
      email: user_params[:email],
      mobile: user_params[:mobile],
      country: 'AUS'
    )
    
    response.data['id']
  end
  
  def create_item(buyer_id:, seller_id:, amount:, description:)
    response = @client.items.create(
      id: "item_#{SecureRandom.hex(8)}",
      name: description,
      amount: (amount.to_f * 100).to_i,
      payment_type: 1,
      buyer_id: buyer_id,
      seller_id: seller_id,
      description: description
    )
    
    response.data['id']
  end
  
  def make_payment(item_id:, card_account_id:)
    response = @client.items.make_payment(
      id: item_id,
      account_id: card_account_id
    )
    
    response.success?
  end
end
```

### Usage Example

```ruby
# In a controller or background job
class ProcessPaymentJob < ApplicationJob
  queue_as :default
  
  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    flow = CardPaymentFlow.new
    
    success = flow.execute(
      buyer_params: {
        id: "buyer_#{transaction.buyer.id}",
        zai_user_id: transaction.buyer.zai_user_id,
        first_name: transaction.buyer.first_name,
        last_name: transaction.buyer.last_name,
        email: transaction.buyer.email,
        mobile: transaction.buyer.phone
      },
      seller_params: {
        id: "seller_#{transaction.seller.id}",
        zai_user_id: transaction.seller.zai_user_id,
        first_name: transaction.seller.first_name,
        last_name: transaction.seller.last_name,
        email: transaction.seller.email,
        mobile: transaction.seller.phone
      },
      payment_params: {
        amount: transaction.amount,
        description: transaction.description,
        card_account_id: transaction.buyer.zai_card_account_id
      }
    )
    
    if success
      transaction.update(status: 'processing')
      PaymentMailer.payment_initiated(transaction).deliver_now
    else
      transaction.update(status: 'failed', error_message: flow.errors.join(', '))
      PaymentMailer.payment_failed(transaction).deliver_now
    end
  end
end
```

## Pre-live Testing

For testing in the pre-live environment:

```ruby
# After making a payment, simulate settlement
class SimulateSettlement
  def self.call(transaction_id)
    transaction = Transaction.find(transaction_id)
    client = ZaiPayment::Client.new
    
    # Step 1: Export batch transactions
    response = client.batch_transactions.export
    batch_transactions = response.data['batch_transactions']
    
    # Find the relevant batch transaction
    batch_tx = batch_transactions.find do |bt|
      bt['related_items']&.include?(transaction.zai_item_id)
    end
    
    return unless batch_tx
    
    # Step 2: Move to batched state (12700)
    client.batches.update_transaction_state(
      id: batch_tx['batch_id'],
      exported_ids: [batch_tx['id']],
      state: 12700
    )
    
    # Step 3: Move to successful state (12000)
    client.batches.update_transaction_state(
      id: batch_tx['batch_id'],
      exported_ids: [batch_tx['id']],
      state: 12000
    )
    
    puts "Settlement simulated for transaction #{transaction_id}"
  end
end
```

## Error Handling

```ruby
# app/services/payment_error_handler.rb
class PaymentErrorHandler
  RETRY_ERRORS = [
    ZaiPayment::Errors::TimeoutError,
    ZaiPayment::Errors::ConnectionError,
    ZaiPayment::Errors::ServerError
  ]
  
  PERMANENT_ERRORS = [
    ZaiPayment::Errors::ValidationError,
    ZaiPayment::Errors::UnauthorizedError,
    ZaiPayment::Errors::ForbiddenError,
    ZaiPayment::Errors::NotFoundError
  ]
  
  def self.handle(error, transaction)
    case error
    when *RETRY_ERRORS
      # Retry the job
      ProcessPaymentJob.set(wait: 5.minutes).perform_later(transaction.id)
    when *PERMANENT_ERRORS
      # Mark as failed permanently
      transaction.update(
        status: 'failed',
        error_message: error.message
      )
      PaymentMailer.payment_error(transaction, error).deliver_now
    when ZaiPayment::Errors::RateLimitError
      # Retry after longer delay
      ProcessPaymentJob.set(wait: 1.hour).perform_later(transaction.id)
    else
      # Log unknown error
      Rails.logger.error("Unknown payment error: #{error.class} - #{error.message}")
      Sentry.capture_exception(error) if defined?(Sentry)
    end
  end
end
```

## Summary

This example demonstrates:

1. **User Creation**: Creating buyer and seller users in Zai
2. **Card Capture**: Using the hosted form to securely capture card details
3. **Item Creation**: Creating a payment item between buyer and seller
4. **Payment Processing**: Making a payment using a card account
5. **Webhook Handling**: Responding to payment events (authorized, completed, settled)
6. **Error Handling**: Properly handling various error scenarios
7. **Testing**: Simulating settlements in pre-live environment

### Payment Flow States

1. **Item Created** → Item exists but no payment made
2. **Payment Initiated** → `make_payment` called
3. **Authorized** → Card transaction successful (webhook: `transactions`)
4. **Completed** → Item status changed to completed (webhook: `items`)
5. **Settled** → Funds moved to seller's wallet (webhook: `batch_transactions`)

### Important Notes

- Always store Zai IDs (`zai_user_id`, `zai_item_id`, `zai_card_account_id`) in your database
- Use webhooks for asynchronous updates rather than polling
- Implement proper error handling and retries
- Use background jobs for payment processing
- Test thoroughly in pre-live environment before production
- Verify webhook signatures for security
- Handle PCI compliance requirements (the hosted form helps with this)


## Reference
- [Zai Cards Payin Workflow](https://developer.hellozai.com/docs/cards-payin-workflow)