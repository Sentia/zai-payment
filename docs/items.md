# Item Management

The Item resource provides methods for managing Zai items, which represent transactions or payments between buyers and sellers on your platform.

## Overview

Items are the core transactional objects in Zai that represent a payment agreement between a buyer (payin user) and a seller (payout user). Each item tracks:
- Transaction amount
- Payment type
- Buyer and seller information
- Fees and charges
- Transaction state and history
- Wire transfer details (if applicable)

## References

- [Zai Items API](https://developer.hellozai.com/reference/listitems)
- [Create Item](https://developer.hellozai.com/reference/createitem)
- [Update Item](https://developer.hellozai.com/reference/updateitem)

## Usage

### Initialize the Item Resource

```ruby
# Using the singleton instance (recommended)
items = ZaiPayment.items

# Or create a new instance
items = ZaiPayment::Resources::Item.new
```

## Methods

### Create Item

Create a new item (transaction/payment) between a buyer and a seller.

#### Required Fields

- `name` - Name/description of the item
- `amount` - Amount in cents (e.g., 10000 = $100.00)
- `payment_type` - Payment type (1-7, default: 2 for credit card)
- `buyer_id` - Buyer user ID
- `seller_id` - Seller user ID

#### Optional Fields

- `id` - Custom unique ID for the item
- `fee_ids` - Array of fee IDs to apply
- `description` - Detailed description
- `currency` - Currency code (e.g., 'AUD', 'USD')
- `custom_descriptor` - Custom text for bank statements
- `buyer_url` - URL for buyer to access transaction
- `seller_url` - URL for seller to access transaction
- `tax_invoice` - Whether to generate a tax invoice (boolean)

#### Example

```ruby
response = ZaiPayment.items.create(
  name: "Product Purchase",
  amount: 10000, # $100.00 in cents
  payment_type: 2, # Credit card
  buyer_id: "buyer-123",
  seller_id: "seller-456",
  description: "Purchase of premium product XYZ",
  currency: "AUD",
  buyer_url: "https://buyer.example.com",
  seller_url: "https://seller.example.com",
  tax_invoice: true
)

if response.success?
  item = response.data
  puts "Item created: #{item['id']}"
  puts "Amount: #{item['amount']}"
  puts "State: #{item['state']}"
end
```

#### Create Item with Custom ID

```ruby
response = ZaiPayment.items.create(
  id: "my-custom-item-#{Time.now.to_i}",
  name: "Custom ID Product",
  amount: 15000,
  payment_type: 2,
  buyer_id: "buyer-123",
  seller_id: "seller-456"
)
```

### List Items

Retrieve a list of all items with pagination and optional filtering.

```ruby
# List items with default pagination (10 items)
response = ZaiPayment.items.list

if response.success?
  items_list = response.data
  items_list.each do |item|
    puts "Item: #{item['name']} - $#{item['amount'] / 100.0}"
  end
  
  # Access pagination metadata
  meta = response.meta
  puts "Total items: #{meta['total']}"
end
```

#### List with Pagination

```ruby
# Get 20 items starting from offset 40
response = ZaiPayment.items.list(limit: 20, offset: 40)
```

#### Search Items

```ruby
# Search items by description
response = ZaiPayment.items.list(search: "product")

# Filter by creation date
response = ZaiPayment.items.list(
  created_after: "2024-01-01T00:00:00Z",
  created_before: "2024-12-31T23:59:59Z"
)

# Combine filters
response = ZaiPayment.items.list(
  limit: 50,
  search: "premium",
  created_after: "2024-01-01T00:00:00Z"
)
```

### Show Item

Get details of a specific item by ID.

```ruby
response = ZaiPayment.items.show("item-123")

if response.success?
  item = response.data
  puts "Item ID: #{item['id']}"
  puts "Name: #{item['name']}"
  puts "Amount: #{item['amount']}"
  puts "Payment Type: #{item['payment_type']}"
  puts "State: #{item['state']}"
  puts "Buyer ID: #{item['buyer_id']}"
  puts "Seller ID: #{item['seller_id']}"
end
```

### Update Item

Update an existing item's details.

```ruby
response = ZaiPayment.items.update(
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
end
```

### Delete Item

Delete an item by ID.

```ruby
response = ZaiPayment.items.delete("item-123")

if response.success?
  puts "Item deleted successfully"
end
```

### Show Item Seller

Get the seller (user) details for a specific item.

```ruby
response = ZaiPayment.items.show_seller("item-123")

if response.success?
  seller = response.data
  puts "Seller: #{seller['first_name']} #{seller['last_name']}"
  puts "Email: #{seller['email']}"
  puts "Country: #{seller['country']}"
end
```

### Show Item Buyer

Get the buyer (user) details for a specific item.

```ruby
response = ZaiPayment.items.show_buyer("item-123")

if response.success?
  buyer = response.data
  puts "Buyer: #{buyer['first_name']} #{buyer['last_name']}"
  puts "Email: #{buyer['email']}"
end
```

### Show Item Fees

Get the fees associated with an item.

```ruby
response = ZaiPayment.items.show_fees("item-123")

if response.success?
  fees = response.data
  
  if fees && fees.any?
    puts "Item has #{fees.length} fee(s):"
    fees.each do |fee|
      puts "  #{fee['name']}: $#{fee['amount'] / 100.0}"
    end
  end
end
```

### Show Item Wire Details

Get wire transfer details for an item (useful for bank transfers).

```ruby
response = ZaiPayment.items.show_wire_details("item-123")

if response.success?
  wire_details = response.data['wire_details']
  
  if wire_details
    puts "Account Number: #{wire_details['account_number']}"
    puts "Routing Number: #{wire_details['routing_number']}"
    puts "Bank Name: #{wire_details['bank_name']}"
  end
end
```

### List Item Transactions

Get all transactions associated with an item.

```ruby
# List transactions with default pagination
response = ZaiPayment.items.list_transactions("item-123")

if response.success?
  transactions = response.data
  
  transactions.each do |transaction|
    puts "Transaction #{transaction['id']}: #{transaction['state']}"
    puts "  Amount: $#{transaction['amount'] / 100.0}"
    puts "  Type: #{transaction['type']}"
  end
end

# List with custom pagination
response = ZaiPayment.items.list_transactions("item-123", limit: 50, offset: 100)
```

### List Item Batch Transactions

Get all batch transactions associated with an item.

```ruby
response = ZaiPayment.items.list_batch_transactions("item-123")

if response.success?
  batch_transactions = response.data
  
  batch_transactions.each do |batch|
    puts "Batch #{batch['id']}: #{batch['state']}"
    puts "  Amount: $#{batch['amount'] / 100.0}"
  end
end

# List with pagination
response = ZaiPayment.items.list_batch_transactions("item-123", limit: 25, offset: 50)
```

### Show Item Status

Get the current status of an item.

```ruby
response = ZaiPayment.items.show_status("item-123")

if response.success?
  status = response.data
  puts "State: #{status['state']}"
  puts "Payment State: #{status['payment_state']}"
  puts "Disbursement State: #{status['disbursement_state']}" if status['disbursement_state']
end
```

### Make Payment

Process a payment for an item using a card account.

```ruby
# Make a payment with required parameters
response = ZaiPayment.items.make_payment(
  "item-123",           # Item ID
  "card_account-456"    # Card account ID
)

if response.success?
  item = response.data
  puts "Payment initiated for item: #{item['id']}"
  puts "State: #{item['state']}"
  puts "Payment State: #{item['payment_state']}"
end
```

#### With Optional Parameters

For enhanced fraud protection, include device and IP address information:

```ruby
response = ZaiPayment.items.make_payment(
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
end
```

### Cancel Item

Cancel a pending item/payment. This operation is typically used to cancel an item before payment has been processed or completed.

```ruby
response = ZaiPayment.items.cancel("item-123")

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

#### Cancel with Status Check

Check item status before attempting to cancel:

```ruby
# Check current status
status_response = ZaiPayment.items.show_status("item-123")

if status_response.success?
  current_state = status_response.data['state']
  
  # Only cancel if in a cancellable state
  if ['pending', 'payment_pending'].include?(current_state)
    cancel_response = ZaiPayment.items.cancel("item-123")
    
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

#### Cancel States and Conditions

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

## Field Reference

### Item Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique item ID (auto-generated if not provided) | Optional |
| `name` | String | Name/title of the item | ✓ |
| `amount` | Integer | Amount in cents (e.g., 10000 = $100.00) | ✓ |
| `payment_type` | Integer | Payment type (1-7, default: 2) | ✓ |
| `buyer_id` | String | Buyer user ID | ✓ |
| `seller_id` | String | Seller user ID | ✓ |
| `fee_ids` | Array | Array of fee IDs to apply | Optional |
| `description` | String | Detailed description | Optional |
| `currency` | String | Currency code (e.g., 'AUD', 'USD') | Optional |
| `custom_descriptor` | String | Custom text for bank statements | Optional |
| `buyer_url` | String | URL for buyer to access transaction | Optional |
| `seller_url` | String | URL for seller to access transaction | Optional |
| `tax_invoice` | Boolean | Whether to generate a tax invoice | Optional |

### Payment Types

When creating items, you can specify different payment types:

| Type | Description |
|------|-------------|
| 1 | Direct Debit |
| 2 | Credit Card (default) |
| 3 | Bank Transfer |
| 4 | Wallet |
| 5 | BPay |
| 6 | PayPal |
| 7 | Other |

Example:

```ruby
# Create item with bank transfer payment type
response = ZaiPayment.items.create(
  name: "Bank Transfer Payment",
  amount: 30000,
  payment_type: 3, # Bank Transfer
  buyer_id: "buyer-123",
  seller_id: "seller-456"
)
```

## Item States

Items go through various states during their lifecycle:

- `pending` - Item created but not yet paid
- `payment_pending` - Payment in progress
- `payment_held` - Payment held (e.g., for review)
- `payment_deposited` - Payment received and deposited
- `work_completed` - Work/delivery completed
- `completed` - Transaction completed successfully
- `refunded` - Transaction refunded
- `cancelled` - Transaction cancelled

Check the item status using `show_status` method to track these state changes.

## Error Handling

The Item resource will raise validation errors for:

- Missing required fields
- Invalid amount (must be positive integer in cents)
- Invalid payment type (must be 1-7)
- Invalid item ID format
- Item not found

```ruby
begin
  response = ZaiPayment.items.create(
    name: "Product",
    amount: -100, # Invalid: negative amount
    payment_type: 2,
    buyer_id: "buyer-123",
    seller_id: "seller-456"
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Item not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### 1. Use Meaningful Names and Descriptions

Always provide clear, descriptive names and descriptions for items. This helps with:
- Transaction tracking
- Customer support
- Financial reconciliation

```ruby
response = ZaiPayment.items.create(
  name: "Order #12345 - Premium Widget",
  description: "Premium widget with extended warranty - Customer: John Doe",
  amount: 29900,
  # ... other fields
)
```

### 2. Track Custom IDs

If you have your own order/transaction IDs, use the optional `id` field:

```ruby
response = ZaiPayment.items.create(
  id: "order-#{your_order_id}",
  name: "Order #{your_order_id}",
  # ... other fields
)
```

### 3. Set Buyer and Seller URLs

Provide URLs so users can access transaction details on your platform:

```ruby
response = ZaiPayment.items.create(
  buyer_url: "https://myapp.com/orders/#{order_id}",
  seller_url: "https://myapp.com/sales/#{order_id}",
  # ... other fields
)
```

### 4. Monitor Transaction Status

Regularly check item status to track payment and disbursement:

```ruby
status_response = ZaiPayment.items.show_status(item_id)
puts "Payment: #{status_response.data['payment_state']}"
puts "Disbursement: #{status_response.data['disbursement_state']}"
```

### 5. Handle Fees Properly

If applying platform fees, create fee objects first and reference them:

```ruby
# Assume you've created fees with IDs: "fee-platform", "fee-service"
response = ZaiPayment.items.create(
  name: "Product Purchase",
  amount: 50000,
  fee_ids: ["fee-platform", "fee-service"],
  # ... other fields
)
```

## Response Structure

### Successful Response

```ruby
response.success? # => true
response.status   # => 200 or 201
response.data     # => Item object hash
response.meta     # => Pagination metadata (for list)
```

### Item Object Example

```ruby
{
  "id" => "item-abc123",
  "name" => "Product Purchase",
  "amount" => 10000,
  "payment_type" => 2,
  "buyer_id" => "buyer-123",
  "seller_id" => "seller-456",
  "description" => "Purchase of product XYZ",
  "currency" => "AUD",
  "state" => "pending",
  "payment_state" => "pending",
  "buyer_url" => "https://buyer.example.com",
  "seller_url" => "https://seller.example.com",
  "tax_invoice" => true,
  "created_at" => "2025-01-01T00:00:00Z",
  "updated_at" => "2025-01-01T00:00:00Z"
}
```

## Complete Workflow Example

Here's a complete example of creating an item and tracking it through its lifecycle:

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
  name: "E-commerce Purchase - Order #12345",
  amount: 50000, # $500.00
  payment_type: 2, # Credit card
  buyer_id: "buyer-abc123",
  seller_id: "seller-xyz789",
  description: "Online store purchase - Premium product bundle",
  currency: "AUD",
  buyer_url: "https://store.example.com/orders/12345",
  seller_url: "https://seller.example.com/sales/12345",
  tax_invoice: true
)

if create_response.success?
  item_id = create_response.data['id']
  puts "✓ Item created: #{item_id}"
  
  # 2. Get item details
  show_response = items.show(item_id)
  puts "✓ Item: #{show_response.data['name']}"
  
  # 3. Get seller details
  seller_response = items.show_seller(item_id)
  puts "✓ Seller: #{seller_response.data['email']}"
  
  # 4. Get buyer details
  buyer_response = items.show_buyer(item_id)
  puts "✓ Buyer: #{buyer_response.data['email']}"
  
  # 5. Check fees
  fees_response = items.show_fees(item_id)
  if fees_response.success? && fees_response.data&.any?
    total_fees = fees_response.data.sum { |f| f['amount'] }
    puts "✓ Total fees: $#{total_fees / 100.0}"
  end
  
  # 6. Monitor status
  status_response = items.show_status(item_id)
  puts "✓ Payment state: #{status_response.data['payment_state']}"
  
  # 7. List transactions
  txn_response = items.list_transactions(item_id)
  puts "✓ Transactions: #{txn_response.data&.length || 0}"
  
  # 8. Update if needed
  update_response = items.update(
    item_id,
    description: "Updated: Order #12345 - Payment confirmed"
  )
  puts "✓ Item updated" if update_response.success?
else
  puts "✗ Error: #{create_response.error_message}"
end
```

## Integration with Rails

### In a Controller

```ruby
class OrdersController < ApplicationController
  def create
    # Create users first (buyer and seller)
    # ... user creation code ...
    
    # Create item
    response = ZaiPayment.items.create(
      name: "Order ##{@order.id}",
      amount: (@order.total * 100).to_i, # Convert to cents
      payment_type: 2,
      buyer_id: @buyer_zai_id,
      seller_id: @seller_zai_id,
      description: @order.description,
      buyer_url: order_url(@order),
      seller_url: seller_order_url(@order),
      tax_invoice: @order.requires_tax_invoice?
    )
    
    if response.success?
      @order.update(zai_item_id: response.data['id'])
      redirect_to @order, notice: 'Order created successfully'
    else
      flash[:error] = "Payment error: #{response.error_message}"
      render :new
    end
  end
  
  def show
    # Get item status from Zai
    if @order.zai_item_id
      response = ZaiPayment.items.show_status(@order.zai_item_id)
      @payment_status = response.data if response.success?
    end
  end
end
```

### In a Background Job

```ruby
class CheckItemStatusJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    
    response = ZaiPayment.items.show_status(order.zai_item_id)
    
    if response.success?
      status = response.data
      
      order.update(
        payment_state: status['payment_state'],
        disbursement_state: status['disbursement_state']
      )
      
      # Send notifications based on state
      if status['payment_state'] == 'completed'
        OrderMailer.payment_completed(order).deliver_later
      end
    end
  end
end
```

## Testing

The Item resource includes comprehensive test coverage. Run the tests with:

```bash
bundle exec rspec spec/zai_payment/resources/item_spec.rb
```

## See Also

- [User Management Guide](users.md) - Managing buyers and sellers
- [Webhook Documentation](webhooks.md) - Receiving item status updates
- [Authentication Documentation](authentication.md) - OAuth2 setup
- [Item Examples](../examples/items.md) - More code examples

## External Resources

- [Zai Items API Reference](https://developer.hellozai.com/reference/listitems)
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Payment Types Documentation](https://developer.hellozai.com/docs/payment-types)

