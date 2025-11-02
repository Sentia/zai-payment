# Zai Payment - Items Examples

This document provides examples of how to use the Items resource in the Zai Payment gem.

## Table of Contents

- [Setup](#setup)
- [Create Item](#create-item)
- [List Items](#list-items)
- [Show Item](#show-item)
- [Update Item](#update-item)
- [Delete Item](#delete-item)
- [Show Item Seller](#show-item-seller)
- [Show Item Buyer](#show-item-buyer)
- [Show Item Fees](#show-item-fees)
- [Show Item Wire Details](#show-item-wire-details)
- [List Item Transactions](#list-item-transactions)
- [List Item Batch Transactions](#list-item-batch-transactions)
- [Show Item Status](#show-item-status)
- [Make Payment](#make-payment)
- [Cancel Item](#cancel-item)

## Setup

```ruby
require 'zai_payment'

# Configure the gem
ZaiPayment.configure do |config|
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.scope = 'your_scope'
  config.environment = :prelive # or :production
end

# Access the items resource
items = ZaiPayment.items
```

## Create Item

Create a new item (transaction/payment) between a buyer and a seller.

```ruby
# Create a basic item
response = items.create(
  name: "Product Purchase",
  amount: 10000, # Amount in cents (100.00)
  payment_type: 2, # Payment type (1-7, 2 is default)
  buyer_id: "buyer-123",
  seller_id: "seller-456"
)

if response.success?
  item = response.data
  puts "Item created: #{item['id']}"
  puts "Name: #{item['name']}"
  puts "Amount: #{item['amount']}"
else
  puts "Error: #{response.error_message}"
end
```

### Create Item with Optional Fields

```ruby
response = items.create(
  name: "Premium Product",
  amount: 25000,
  payment_type: 2,
  buyer_id: "buyer-123",
  seller_id: "seller-456",
  description: "Purchase of premium product XYZ",
  currency: "AUD",
  fee_ids: ["fee-1", "fee-2"],
  custom_descriptor: "MY STORE PURCHASE",
  buyer_url: "https://buyer.example.com",
  seller_url: "https://seller.example.com",
  tax_invoice: true
)

if response.success?
  item = response.data
  puts "Item created with ID: #{item['id']}"
  puts "Description: #{item['description']}"
  puts "Tax Invoice: #{item['tax_invoice']}"
end
```

### Create Item with Custom ID

```ruby
response = items.create(
  id: "my-custom-item-#{Time.now.to_i}",
  name: "Custom ID Product",
  amount: 15000,
  payment_type: 2,
  buyer_id: "buyer-123",
  seller_id: "seller-456"
)

if response.success?
  item = response.data
  puts "Item created with custom ID: #{item['id']}"
end
```

## List Items

Retrieve a list of all items with pagination and optional search/filtering.

```ruby
# List items with default pagination (10 items)
response = items.list

if response.success?
  items_list = response.data
  items_list.each do |item|
    puts "Item ID: #{item['id']}, Name: #{item['name']}, Amount: #{item['amount']}"
  end
  
  # Access metadata
  meta = response.meta
  puts "Total items: #{meta['total']}"
  puts "Limit: #{meta['limit']}"
  puts "Offset: #{meta['offset']}"
end
```

### List Items with Custom Pagination

```ruby
# List 20 items starting from offset 40
response = items.list(limit: 20, offset: 40)

if response.success?
  items_list = response.data
  puts "Retrieved #{items_list.length} items"
end
```

### Search Items by Description

```ruby
# Search for items with "product" in the description
response = items.list(search: "product")

if response.success?
  items_list = response.data
  puts "Found #{items_list.length} items matching 'product'"
  items_list.each do |item|
    puts "  - #{item['name']}: #{item['description']}"
  end
end
```

### Filter Items by Creation Date

```ruby
# Get items created in a specific date range
response = items.list(
  created_after: "2024-01-01T00:00:00Z",
  created_before: "2024-12-31T23:59:59Z"
)

if response.success?
  items_list = response.data
  puts "Found #{items_list.length} items created in 2024"
end
```

### Combine Search and Filters

```ruby
# Search with pagination and date filters
response = items.list(
  limit: 50,
  offset: 0,
  search: "premium",
  created_after: "2024-01-01T00:00:00Z"
)

if response.success?
  items_list = response.data
  puts "Found #{items_list.length} premium items created after Jan 1, 2024"
end
```

## Show Item

Get details of a specific item by ID.

```ruby
response = items.show("item-123")

if response.success?
  item = response.data
  puts "Item ID: #{item['id']}"
  puts "Name: #{item['name']}"
  puts "Amount: #{item['amount']}"
  puts "Payment Type: #{item['payment_type']}"
  puts "Buyer ID: #{item['buyer_id']}"
  puts "Seller ID: #{item['seller_id']}"
  puts "Description: #{item['description']}"
  puts "State: #{item['state']}"
  puts "Buyer URL: #{item['buyer_url']}" if item['buyer_url']
  puts "Seller URL: #{item['seller_url']}" if item['seller_url']
  puts "Tax Invoice: #{item['tax_invoice']}" unless item['tax_invoice'].nil?
else
  puts "Error: #{response.error_message}"
end
```

## Update Item

Update an existing item's details.

```ruby
response = items.update(
  "item-123",
  name: "Updated Product Name",
  description: "Updated product description",
  amount: 12000,
  buyer_url: "https://new-buyer.example.com",
  tax_invoice: false
)

if response.success?
  item = response.data
  puts "Item updated: #{item['id']}"
  puts "New name: #{item['name']}"
  puts "New amount: #{item['amount']}"
  puts "Tax Invoice: #{item['tax_invoice']}"
else
  puts "Error: #{response.error_message}"
end
```

### Update Item Seller or Buyer

```ruby
response = items.update(
  "item-123",
  seller_id: "new-seller-789",
  buyer_id: "new-buyer-012"
)

if response.success?
  puts "Item updated with new buyer and seller"
end
```

## Delete Item

Delete an item by ID.

```ruby
response = items.delete("item-123")

if response.success?
  puts "Item deleted successfully"
else
  puts "Error: #{response.error_message}"
end
```

## Show Item Seller

Get the seller (user) details for a specific item.

```ruby
response = items.show_seller("item-123")

if response.success?
  seller = response.data
  puts "Seller ID: #{seller['id']}"
  puts "Seller Email: #{seller['email']}"
  puts "Seller Name: #{seller['first_name']} #{seller['last_name']}"
  puts "Country: #{seller['country']}"
else
  puts "Error: #{response.error_message}"
end
```

## Show Item Buyer

Get the buyer (user) details for a specific item.

```ruby
response = items.show_buyer("item-123")

if response.success?
  buyer = response.data
  puts "Buyer ID: #{buyer['id']}"
  puts "Buyer Email: #{buyer['email']}"
  puts "Buyer Name: #{buyer['first_name']} #{buyer['last_name']}"
  puts "Country: #{buyer['country']}"
else
  puts "Error: #{response.error_message}"
end
```

## Show Item Fees

Get the fees associated with an item.

```ruby
response = items.show_fees("item-123")

if response.success?
  fees = response.data
  
  if fees && fees.any?
    puts "Item has #{fees.length} fee(s):"
    fees.each do |fee|
      puts "  Fee ID: #{fee['id']}"
      puts "  Name: #{fee['name']}"
      puts "  Amount: #{fee['amount']}"
      puts "  Fee Type: #{fee['fee_type']}"
    end
  else
    puts "No fees associated with this item"
  end
else
  puts "Error: #{response.error_message}"
end
```

## Show Item Wire Details

Get wire transfer details for an item.

```ruby
response = items.show_wire_details("item-123")

if response.success?
  wire_details = response.data['wire_details']
  
  if wire_details
    puts "Wire Transfer Details:"
    puts "  Account Number: #{wire_details['account_number']}"
    puts "  Routing Number: #{wire_details['routing_number']}"
    puts "  Bank Name: #{wire_details['bank_name']}"
    puts "  Swift Code: #{wire_details['swift_code']}"
  else
    puts "No wire details available for this item"
  end
else
  puts "Error: #{response.error_message}"
end
```

## List Item Transactions

Get all transactions associated with an item.

```ruby
# List transactions with default pagination
response = items.list_transactions("item-123")

if response.success?
  transactions = response.data
  
  if transactions && transactions.any?
    puts "Item has #{transactions.length} transaction(s):"
    transactions.each do |transaction|
      puts "  Transaction ID: #{transaction['id']}"
      puts "  Amount: #{transaction['amount']}"
      puts "  State: #{transaction['state']}"
      puts "  Type: #{transaction['type']}"
      puts "  Created At: #{transaction['created_at']}"
    end
  else
    puts "No transactions found for this item"
  end
else
  puts "Error: #{response.error_message}"
end
```

### List Item Transactions with Pagination

```ruby
# List 50 transactions starting from offset 100
response = items.list_transactions("item-123", limit: 50, offset: 100)

if response.success?
  transactions = response.data
  puts "Retrieved #{transactions.length} transactions"
end
```

## List Item Batch Transactions

Get all batch transactions associated with an item.

```ruby
response = items.list_batch_transactions("item-123")

if response.success?
  batch_transactions = response.data
  
  if batch_transactions && batch_transactions.any?
    puts "Item has #{batch_transactions.length} batch transaction(s):"
    batch_transactions.each do |batch|
      puts "  Batch ID: #{batch['id']}"
      puts "  Amount: #{batch['amount']}"
      puts "  State: #{batch['state']}"
      puts "  Created At: #{batch['created_at']}"
    end
  else
    puts "No batch transactions found for this item"
  end
else
  puts "Error: #{response.error_message}"
end
```

### List Item Batch Transactions with Pagination

```ruby
# List 25 batch transactions starting from offset 50
response = items.list_batch_transactions("item-123", limit: 25, offset: 50)

if response.success?
  batch_transactions = response.data
  puts "Retrieved #{batch_transactions.length} batch transactions"
end
```

## Show Item Status

Get the current status of an item.

```ruby
response = items.show_status("item-123")

if response.success?
  item_status = response.data
  puts "Item ID: #{item_status['id']}"
  puts "State: #{item_status['state']}"
  puts "Payment State: #{item_status['payment_state']}"
  puts "Disbursement State: #{item_status['disbursement_state']}" if item_status['disbursement_state']
  puts "Status Description: #{item_status['status_description']}" if item_status['status_description']
else
  puts "Error: #{response.error_message}"
end
```

## Make Payment

Process a payment for an item using a card account. This method charges the buyer's card and initiates the payment flow.

### Basic Payment

```ruby
# Make a payment with just the required parameters
response = items.make_payment(
  "item-123",           # Item ID
  "card_account-456"    # Card account ID
)

if response.success?
  item = response.data
  puts "Payment initiated for item: #{item['id']}"
  puts "State: #{item['state']}"
  puts "Payment State: #{item['payment_state']}"
else
  puts "Payment failed: #{response.error_message}"
end
```

### Payment with Device Information

For enhanced fraud protection, include device and IP address information:

```ruby
response = items.make_payment(
  "item-123",
  "card_account-456",
  device_id: "device_789",
  ip_address: request.remote_ip  # In a Rails controller
)

if response.success?
  puts "Payment processed with device tracking"
end
```

### Payment with CVV

Some card payments may require CVV verification:

```ruby
response = items.make_payment(
  "item-123",
  "card_account-456",
  cvv: "123"  # CVV from secure form
)

if response.success?
  puts "Payment processed with CVV verification"
end
```

### Payment with All Optional Parameters

Maximum fraud protection with all available parameters:

```ruby
response = items.make_payment(
  "item-123",
  "card_account-456",
  device_id: "device_789",
  ip_address: "192.168.1.1",
  cvv: "123",
  merchant_phone: "+61412345678"
)

if response.success?
  item = response.data
  puts "Payment initiated successfully"
  puts "Item State: #{item['state']}"
  puts "Payment State: #{item['payment_state']}"
  puts "Amount: #{item['amount']}"
else
  puts "Payment failed: #{response.error_message}"
end
```

### Error Handling for Payments

```ruby
begin
  response = items.make_payment("item-123", "card_account-456")
  
  if response.success?
    puts "Payment successful"
  else
    # Handle API errors
    case response.status
    when 422
      puts "Validation error: #{response.error_message}"
      # Common: Insufficient funds, card declined, etc.
    when 404
      puts "Item or card account not found"
    when 401
      puts "Authentication failed"
    else
      puts "Payment error: #{response.error_message}"
    end
  end
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Real-World Payment Flow Example

Complete example showing item creation through payment:

```ruby
require 'zai_payment'

# Configure
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
  config.environment = :prelive
end

items = ZaiPayment.items

# Step 1: Create an item
create_response = items.create(
  name: "Product Purchase",
  amount: 10000,  # $100.00
  payment_type: 2,
  buyer_id: "buyer-123",
  seller_id: "seller-456",
  description: "Purchase of premium widget"
)

if create_response.success?
  item_id = create_response.data['id']
  puts "✓ Item created: #{item_id}"
  
  # Step 2: Make the payment
  payment_response = items.make_payment(
    item_id,
    "card_account-789",  # Buyer's card account
    ip_address: "192.168.1.1",
    device_id: "device_abc123"
  )
  
  if payment_response.success?
    puts "✓ Payment initiated"
    puts "  State: #{payment_response.data['state']}"
    puts "  Payment State: #{payment_response.data['payment_state']}"
    
    # Step 3: Check payment status
    sleep 2  # Wait for processing
    
    status_response = items.show_status(item_id)
    if status_response.success?
      status = status_response.data
      puts "✓ Current status:"
      puts "  State: #{status['state']}"
      puts "  Payment State: #{status['payment_state']}"
    end
  else
    puts "✗ Payment failed: #{payment_response.error_message}"
  end
else
  puts "✗ Item creation failed: #{create_response.error_message}"
end
```

### Payment States

After calling `make_payment`, the item will go through several states:

| State | Description |
|-------|-------------|
| `payment_pending` | Payment has been initiated |
| `payment_processing` | Card is being charged |
| `completed` | Payment successful, funds held in escrow |
| `payment_held` | Payment succeeded but held for review |
| `payment_failed` | Payment failed (card declined, insufficient funds, etc.) |

### Webhook Integration

After making a payment, listen for webhook events to track the payment status:

```ruby
# In your webhook handler
def handle_transaction_webhook(payload)
  if payload['type'] == 'payment' && payload['status'] == 'successful'
    item_id = payload['related_items'].first
    puts "Payment successful for item: #{item_id}"
    
    # Update your database
    Order.find_by(zai_item_id: item_id).update(status: 'paid')
  elsif payload['status'] == 'failed'
    puts "Payment failed: #{payload['failure_reason']}"
  end
end
```

## Complete Workflow Example

Here's a complete example of creating an item and performing various operations on it:

```ruby
require 'zai_payment'

# Configure
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
  config.environment = :prelive
end

items = ZaiPayment.items

# 1. Create an item
create_response = items.create(
  name: "E-commerce Purchase",
  amount: 50000, # $500.00
  payment_type: 2,
  buyer_id: "buyer-abc123",
  seller_id: "seller-xyz789",
  description: "Online store purchase - Order #12345",
  currency: "AUD",
  buyer_url: "https://buyer-portal.example.com",
  seller_url: "https://seller-portal.example.com",
  tax_invoice: true
)

if create_response.success?
  item_id = create_response.data['id']
  puts "✓ Item created: #{item_id}"
  
  # 2. Get item details
  show_response = items.show(item_id)
  if show_response.success?
    puts "✓ Item retrieved: #{show_response.data['name']}"
  end
  
  # 3. Get seller details
  seller_response = items.show_seller(item_id)
  if seller_response.success?
    seller = seller_response.data
    puts "✓ Seller: #{seller['email']}"
  end
  
  # 4. Get buyer details
  buyer_response = items.show_buyer(item_id)
  if buyer_response.success?
    buyer = buyer_response.data
    puts "✓ Buyer: #{buyer['email']}"
  end
  
  # 5. Check item status
  status_response = items.show_status(item_id)
  if status_response.success?
    status = status_response.data
    puts "✓ Item status: #{status['state']}"
  end
  
  # 6. List transactions
  transactions_response = items.list_transactions(item_id)
  if transactions_response.success?
    txn_count = transactions_response.data&.length || 0
    puts "✓ Item has #{txn_count} transaction(s)"
  end
  
  # 7. Update item if needed
  update_response = items.update(
    item_id,
    description: "Updated: Online store purchase - Order #12345 (Confirmed)",
    tax_invoice: true
  )
  if update_response.success?
    puts "✓ Item updated successfully"
  end
else
  puts "✗ Error creating item: #{create_response.error_message}"
end
```

## Error Handling

Always check the response status and handle errors appropriately:

```ruby
response = items.show("item-123")

if response.success?
  # Handle successful response
  item = response.data
  puts "Item: #{item['name']}"
else
  # Handle error
  case response.status
  when 404
    puts "Item not found"
  when 401
    puts "Authentication failed - check your credentials"
  when 422
    puts "Validation error: #{response.error_message}"
  else
    puts "Error: #{response.error_message}"
  end
end
```

## Cancel Item

Cancel an existing item/payment. This operation is typically used to cancel a pending payment before it has been processed or completed.

### Basic Cancel

```ruby
response = items.cancel("item-123")

if response.success?
  item = response.data
  puts "Item cancelled successfully"
  puts "Item ID: #{item['id']}"
  puts "State: #{item['state']}"
  puts "Payment State: #{item['payment_state']}"
else
  puts "Cancel failed: #{response.error_message}"
end
```

### Cancel with Error Handling

```ruby
begin
  response = items.cancel("item-123")
  
  if response.success?
    item = response.data
    puts "✓ Item cancelled: #{item['id']}"
    puts "  State: #{item['state']}"
    puts "  Payment State: #{item['payment_state']}"
  else
    # Handle API errors
    case response.status
    when 422
      puts "Cannot cancel: #{response.error_message}"
      # Common: Item already completed or in a state that can't be cancelled
    when 404
      puts "Item not found"
    when 401
      puts "Authentication failed"
    else
      puts "Cancellation error: #{response.error_message}"
    end
  end
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Item not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Cancel with Status Check

Check item status before attempting to cancel:

```ruby
# Check current status
status_response = items.show_status("item-123")

if status_response.success?
  status = status_response.data
  current_state = status['state']
  payment_state = status['payment_state']
  
  puts "Current state: #{current_state}"
  puts "Payment state: #{payment_state}"
  
  # Only cancel if in a cancellable state
  if ['pending', 'payment_pending'].include?(current_state)
    cancel_response = items.cancel("item-123")
    
    if cancel_response.success?
      puts "✓ Item cancelled successfully"
    else
      puts "✗ Cancel failed: #{cancel_response.error_message}"
    end
  else
    puts "Item cannot be cancelled - current state: #{current_state}"
  end
end
```

### Real-World Cancel Flow Example

Complete example showing item creation, payment, and cancellation:

```ruby
require 'zai_payment'

# Configure
ZaiPayment.configure do |config|
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
  config.environment = :prelive
end

items = ZaiPayment.items

# Step 1: Create an item
create_response = items.create(
  name: "Product Purchase",
  amount: 10000,  # $100.00
  payment_type: 2,
  buyer_id: "buyer-123",
  seller_id: "seller-456",
  description: "Purchase of premium widget"
)

if create_response.success?
  item_id = create_response.data['id']
  puts "✓ Item created: #{item_id}"
  
  # Step 2: Customer decides to cancel before payment
  puts "\nCustomer requested cancellation..."
  
  # Step 3: Check if item can be cancelled
  status_response = items.show_status(item_id)
  
  if status_response.success?
    current_state = status_response.data['state']
    puts "Current item state: #{current_state}"
    
    # Step 4: Cancel the item
    if ['pending', 'payment_pending'].include?(current_state)
      cancel_response = items.cancel(item_id)
      
      if cancel_response.success?
        cancelled_item = cancel_response.data
        puts "✓ Item cancelled successfully"
        puts "  Final state: #{cancelled_item['state']}"
        puts "  Payment state: #{cancelled_item['payment_state']}"
        
        # Notify customer
        # CustomerMailer.order_cancelled(customer_email, item_id).deliver_later
      else
        puts "✗ Cancellation failed: #{cancel_response.error_message}"
      end
    else
      puts "✗ Item cannot be cancelled - current state: #{current_state}"
    end
  end
else
  puts "✗ Item creation failed: #{create_response.error_message}"
end
```

### Cancel States and Conditions

Items can typically be cancelled when in these states:

| State | Can Cancel? | Description |
|-------|-------------|-------------|
| `pending` | ✓ Yes | Item created but no payment initiated |
| `payment_pending` | ✓ Yes | Payment initiated but not yet processed |
| `payment_processing` | Maybe | Depends on payment processor |
| `completed` | ✗ No | Payment completed, must refund instead |
| `payment_held` | Maybe | May require admin approval |
| `cancelled` | ✗ No | Already cancelled |
| `refunded` | ✗ No | Already refunded |

**Note:** If an item is already completed or funds have been disbursed, you cannot cancel it. In those cases, you may need to process a refund instead (contact Zai support for refund procedures).

### Integration with Rails

#### In a Controller

```ruby
class OrdersController < ApplicationController
  def cancel
    @order = Order.find(params[:id])
    
    # Ensure order belongs to current user
    unless @order.user == current_user
      redirect_to root_path, alert: 'Unauthorized'
      return
    end
    
    # Cancel in Zai
    response = ZaiPayment.items.cancel(@order.zai_item_id)
    
    if response.success?
      @order.update(
        status: 'cancelled',
        cancelled_at: Time.current
      )
      
      redirect_to @order, notice: 'Order cancelled successfully'
    else
      flash[:error] = "Cannot cancel order: #{response.error_message}"
      redirect_to @order
    end
  rescue ZaiPayment::Errors::ValidationError => e
    flash[:error] = "Cancellation error: #{e.message}"
    redirect_to @order
  end
end
```

#### In a Service Object

```ruby
class OrderCancellationService
  def initialize(order)
    @order = order
  end
  
  def cancel
    # Check if order can be cancelled
    unless cancellable?
      return { success: false, error: 'Order cannot be cancelled' }
    end
    
    # Cancel in Zai
    response = ZaiPayment.items.cancel(@order.zai_item_id)
    
    if response.success?
      # Update local database
      @order.update(
        status: 'cancelled',
        zai_state: response.data['state'],
        zai_payment_state: response.data['payment_state'],
        cancelled_at: Time.current,
        cancelled_by: @order.user_id
      )
      
      # Send notification
      OrderMailer.order_cancelled(@order).deliver_later
      
      # Refund any processing fees if applicable
      process_fee_refund if @order.processing_fee.present?
      
      { success: true, order: @order }
    else
      { success: false, error: response.error_message }
    end
  rescue ZaiPayment::Errors::ApiError => e
    { success: false, error: e.message }
  end
  
  private
  
  def cancellable?
    # Check local status
    return false unless @order.status.in?(['pending', 'payment_pending'])
    
    # Check Zai status
    status_response = ZaiPayment.items.show_status(@order.zai_item_id)
    return false unless status_response.success?
    
    status_response.data['state'].in?(['pending', 'payment_pending'])
  rescue
    false
  end
  
  def process_fee_refund
    # Custom logic for refunding processing fees
    # ...
  end
end

# Usage:
# service = OrderCancellationService.new(order)
# result = service.cancel
# if result[:success]
#   # Handle success
# else
#   # Handle error: result[:error]
# end
```

### Webhook Integration

After cancelling an item, you may receive webhook notifications:

```ruby
# In your webhook handler
def handle_item_webhook(payload)
  if payload['type'] == 'item' && payload['status'] == 'cancelled'
    item_id = payload['id']
    puts "Item cancelled: #{item_id}"
    
    # Update your database
    Order.find_by(zai_item_id: item_id)&.update(
      status: 'cancelled',
      zai_state: payload['state'],
      cancelled_at: Time.current
    )
    
    # Notify customer
    order = Order.find_by(zai_item_id: item_id)
    OrderMailer.cancellation_confirmed(order).deliver_later if order
  end
end
```

### Testing Cancel Functionality

```ruby
# spec/services/order_cancellation_service_spec.rb
RSpec.describe OrderCancellationService do
  let(:order) { create(:order, status: 'pending', zai_item_id: 'item-123') }
  let(:service) { described_class.new(order) }
  
  describe '#cancel' do
    context 'when order can be cancelled' do
      before do
        allow(ZaiPayment.items).to receive(:show_status).and_return(
          double(success?: true, data: { 'state' => 'pending' })
        )
        
        allow(ZaiPayment.items).to receive(:cancel).and_return(
          double(
            success?: true, 
            data: { 'id' => 'item-123', 'state' => 'cancelled', 'payment_state' => 'cancelled' }
          )
        )
      end
      
      it 'successfully cancels the order' do
        result = service.cancel
        
        expect(result[:success]).to be true
        expect(order.reload.status).to eq('cancelled')
        expect(order.cancelled_at).to be_present
      end
    end
    
    context 'when order cannot be cancelled' do
      before do
        order.update(status: 'completed')
      end
      
      it 'returns error' do
        result = service.cancel
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('cannot be cancelled')
      end
    end
  end
end
```

## Payment Types

When creating items, you can specify different payment types:

- **1**: Direct Debit
- **2**: Credit Card (default)
- **3**: Bank Transfer
- **4**: Wallet
- **5**: BPay
- **6**: PayPal
- **7**: Other

Example:

```ruby
# Create item with bank transfer payment type
response = items.create(
  name: "Bank Transfer Payment",
  amount: 30000,
  payment_type: 3, # Bank Transfer
  buyer_id: "buyer-123",
  seller_id: "seller-456"
)
```

## API Reference

For more information about the Zai Items API, see:

- [Create Item](https://developer.hellozai.com/reference/createitem)
- [List Items](https://developer.hellozai.com/reference/listitems)
- [Show Item](https://developer.hellozai.com/reference/showitem)
- [Update Item](https://developer.hellozai.com/reference/updateitem)
- [Delete Item](https://developer.hellozai.com/reference/deleteitem)
- [Show Item Seller](https://developer.hellozai.com/reference/showitemseller)
- [Show Item Buyer](https://developer.hellozai.com/reference/showitembuyer)
- [Show Item Fees](https://developer.hellozai.com/reference/showitemfees)
- [Show Item Wire Details](https://developer.hellozai.com/reference/showitemwiredetails)
- [List Item Transactions](https://developer.hellozai.com/reference/listitemtransactions)
- [List Item Batch Transactions](https://developer.hellozai.com/reference/listitembatchtransactions)
- [Show Item Status](https://developer.hellozai.com/reference/showitemstatus)
- [Make Payment](https://developer.hellozai.com/reference/makepayment)
- [Cancel Item](https://developer.hellozai.com/reference/cancelitem)

