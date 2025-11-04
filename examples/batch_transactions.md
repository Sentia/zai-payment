# Batch Transactions (Prelive Only)

## Overview

The batch transaction endpoints allow you to work with batch transactions in both prelive and production environments. The prelive-specific endpoints are used for testing and simulation.

### Available Operations

1. **List Batch Transactions** - Query and filter batch transactions (all environments)
2. **Show Batch Transaction** - Get a single batch transaction by ID (all environments)
3. **Export Transactions** - Export pending transactions to batched state (prelive only)
4. **Update Transaction States** - Move transactions through processing states (prelive only)

## Configuration

First, ensure your configuration is set to use the prelive environment:

```ruby
ZaiPayment.configure do |config|
  config.environment = :prelive # Required for batch transaction endpoints
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.scope = 'your_scope'
end
```

## Usage

### List Batch Transactions

List and filter batch transactions. Available in all environments.

```ruby
# List all batch transactions
response = ZaiPayment.batch_transactions.list

response.data
# => [
#   {
#     "id" => 12484,
#     "status" => 12200,
#     "reference_id" => "7190770-1-2908",
#     "type" => "disbursement",
#     "type_method" => "direct_credit",
#     "state" => "batched",
#     ...
#   }
# ]

# Filter by transaction type
response = ZaiPayment.batch_transactions.list(
  transaction_type: 'disbursement',
  limit: 50
)

# Filter by direction and date range
response = ZaiPayment.batch_transactions.list(
  direction: 'credit',
  created_after: '2024-01-01T00:00:00Z',
  created_before: '2024-12-31T23:59:59Z'
)

# Filter by batch ID
response = ZaiPayment.batch_transactions.list(
  batch_id: '241',
  limit: 100
)

# Available filters:
# - limit: number of records (default: 10, max: 200)
# - offset: pagination offset (default: 0)
# - account_id: filter by account ID
# - batch_id: filter by batch ID
# - item_id: filter by item ID
# - transaction_type: payment, refund, disbursement, fee, deposit, withdrawal
# - transaction_type_method: credit_card, npp, bpay, wallet_account_transfer, wire_transfer, misc
# - direction: debit or credit
# - created_before: ISO 8601 date/time
# - created_after: ISO 8601 date/time
# - disbursement_bank: bank used for disbursing
# - processing_bank: bank used for processing
```

### Show Batch Transaction

Get a single batch transaction using its ID. You can use either the UUID or numeric ID.

```ruby
# Get by UUID
response = ZaiPayment.batch_transactions.show('90c1418b-f4f4-413e-a4ba-f29c334e7f55')

response.data
# => {
#   "created_at" => "2020-05-05T12:26:59.112Z",
#   "updated_at" => "2020-05-05T12:31:03.389Z",
#   "id" => 13143,
#   "reference_id" => "7190770-1-2908",
#   "uuid" => "90c1418b-f4f4-413e-a4ba-f29c334e7f55",
#   "account_external" => {
#     "account_type_id" => 9100,
#     "currency" => { "code" => "AUD" }
#   },
#   "user_email" => "assemblybuyer71391895@assemblypayments.com",
#   "first_name" => "Buyer",
#   "last_name" => "Last Name",
#   "legal_entity_id" => "5f46763e-fb7a-4feb-9820-93a5703ddd17",
#   "user_external_id" => "buyer-71391895",
#   "phone" => "+1588681395",
#   "marketplace" => {
#     "name" => "platform1556505750",
#     "uuid" => "041e8015-5101-44f1-9b7d-6a206603f29f"
#   },
#   "account_type" => 9100,
#   "type" => "payment",
#   "type_method" => "direct_debit",
#   "batch_id" => 245,
#   "reference" => "platform1556505750",
#   "state" => "successful",
#   "status" => 12000,
#   "user_id" => "1ea8d380-70f9-0138-ba3b-0a58a9feac06",
#   "account_id" => "26065be0-70f9-0138-9abc-0a58a9feac06",
#   "from_user_name" => "Neol1604984243 Calangi",
#   "from_user_id" => 1604984243,
#   "amount" => 109,
#   "currency" => "AUD",
#   "debit_credit" => "debit",
#   "description" => "Debit of $1.09 from Bank Account for Credit of $1.09 to Item",
#   "related" => {
#     "account_to" => {
#       "id" => "edf4e4ef-0d78-48db-85e0-0af04c5dc2d6",
#       "account_type" => "item",
#       "user_id" => "5b9fe350-4c56-0137-e134-0242ac110002"
#     }
#   },
#   "links" => {
#     "self" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55",
#     "users" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/users",
#     "fees" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/fees",
#     "wallet_accounts" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/wallet_accounts",
#     "card_accounts" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/card_accounts",
#     "paypal_accounts" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/paypal_accounts",
#     "bank_accounts" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/bank_accounts",
#     "items" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/items",
#     "marketplace" => "/batch_transactions/90c1418b-f4f4-413e-a4ba-f29c334e7f55/marketplaces"
#   }
# }

# Get by numeric ID
response = ZaiPayment.batch_transactions.show('13143')
response.data['id'] # => 13143

# Check transaction state
response = ZaiPayment.batch_transactions.show('90c1418b-f4f4-413e-a4ba-f29c334e7f55')
response.data['state'] # => "successful"
response.data['status'] # => 12000
```

### Step 1: Export Transactions (Prelive Only)

Call the `GET /batch_transactions/export_transactions` API which moves all pending batch_transactions into batched state. This will return all the batch_transactions that have moved from pending to batched, including their `batch_id` which you'll need for the next steps.

```ruby
# Export all pending transactions to batched state
response = ZaiPayment.batch_transactions.export_transactions

# The response contains transactions with their batch_id
response.data
# => [
#   {
#     "id" => "439970a2-e0a1-418e-aecf-6b519c115c55",
#     "batch_id" => "dabcfd50-bf5a-0138-7b40-0a58a9feac03",
#     "status" => "batched",
#     "type" => "payment_funding",
#     "type_method" => "credit_card"
#   }
# ]

# Store the batch_id and transaction id for next steps
batch_id = response.data.first['batch_id']
transaction_id = response.data.first['id']
```

**Important:** When you simulate a payment journey in Pre-live, the response including the transaction `id` will be cleared after a day. If you need to retrieve this `id`, you can call the List Transactions API, input a limited number of results depending on how much time has passed, and then find it from that list of transactions.

### Step 2: Move to Bank Processing State

Move one or more batch_transactions into `bank_processing` state (state code: `12700`). You need to pass the `batch_id` from step 1.

```ruby
# Using the general method with state code
response = ZaiPayment.batch_transactions.update_transaction_states(
  batch_id,
  exported_ids: [transaction_id],
  state: 12700
)

# Or use the convenience method
response = ZaiPayment.batch_transactions.process_to_bank_processing(
  batch_id,
  exported_ids: [transaction_id]
)

response.body
# => {
#   "aggregated_jobs_uuid" => "c1cbc502-9754-42fd-9731-2330ddd7a41f",
#   "msg" => "1 jobs have been sent to the queue.",
#   "errors" => []
# }
```

### Step 3: Move to Successful State

Move one or more batch_transactions to the final state of processing being `successful` (state code: `12000`). This simulates the completion of the card funding payment processing and will trigger a `batch_transactions` webhook.

```ruby
# Using the general method with state code
response = ZaiPayment.batch_transactions.update_transaction_states(
  batch_id,
  exported_ids: [transaction_id],
  state: 12000
)

# Or use the convenience method
response = ZaiPayment.batch_transactions.process_to_successful(
  batch_id,
  exported_ids: [transaction_id]
)

response.body
# => {
#   "aggregated_jobs_uuid" => "c1cbc502-9754-42fd-9731-2330ddd7a41f",
#   "msg" => "1 jobs have been sent to the queue.",
#   "errors" => []
# }
```

### Processing Multiple Transactions

You can process multiple transactions at once by passing an array of transaction IDs:

```ruby
# Export transactions first
export_response = ZaiPayment.batch_transactions.export_transactions
batch_id = export_response.data.first['batch_id']
transaction_ids = export_response.data.map { |t| t['id'] }

# Process all to bank_processing
ZaiPayment.batch_transactions.process_to_bank_processing(
  batch_id,
  exported_ids: transaction_ids
)

# Then process all to successful
ZaiPayment.batch_transactions.process_to_successful(
  batch_id,
  exported_ids: transaction_ids
)
```

## Complete Example

Here's a complete example of the full workflow:

```ruby
# Configure the client for prelive
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end

# Step 1: Export pending transactions to batched state
export_response = ZaiPayment.batch_transactions.export_transactions

if export_response.success?
  puts "Exported #{export_response.data.length} transactions"
  
  # Get batch_id and transaction ids
  batch_id = export_response.data.first['batch_id']
  transaction_ids = export_response.data.map { |t| t['id'] }
  
  puts "Batch ID: #{batch_id}"
  puts "Transaction IDs: #{transaction_ids.join(', ')}"
  
  # Step 2: Move to bank_processing state
  processing_response = ZaiPayment.batch_transactions.process_to_bank_processing(
    batch_id,
    exported_ids: transaction_ids
  )
  
  if processing_response.success?
    puts "Moved to bank_processing state (12700)"
    
    # Step 3: Move to successful state (triggers webhook)
    success_response = ZaiPayment.batch_transactions.process_to_successful(
      batch_id,
      exported_ids: transaction_ids
    )
    
    if success_response.success?
      puts "Moved to successful state (12000)"
      puts "Webhook should be triggered for these transactions"
    else
      puts "Error moving to successful state: #{success_response.body}"
    end
  else
    puts "Error moving to bank_processing: #{processing_response.body}"
  end
else
  puts "Error exporting transactions: #{export_response.body}"
end
```

## Querying Batch Transactions

If you need more information on the item, transactions, or batch_transaction, you can use the `show` method:

```ruby
# Query a specific batch transaction by UUID
response = ZaiPayment.batch_transactions.show('90c1418b-f4f4-413e-a4ba-f29c334e7f55')

# Access transaction details
response.data['state'] # => "successful"
response.data['amount'] # => 109
response.data['currency'] # => "AUD"
response.data['type'] # => "payment"
response.data['type_method'] # => "direct_debit"

# Or query by numeric ID
response = ZaiPayment.batch_transactions.show('13143')
```

## State Codes

- **12700**: `bank_processing` - Transactions are being processed by the bank
- **12000**: `successful` - Final state, processing complete, triggers webhook

## Error Handling

The batch transaction endpoints will raise errors in the following cases:

### ConfigurationError

Raised when attempting to use batch transaction endpoints in production environment:

```ruby
begin
  ZaiPayment.batch_transactions.export_transactions
rescue ZaiPayment::Errors::ConfigurationError => e
  puts e.message
  # => "Batch transaction endpoints are only available in prelive environment. Current environment: production"
end
```

### ValidationError

Raised when parameters are invalid:

```ruby
# Empty batch_id
ZaiPayment.batch_transactions.process_to_bank_processing('', exported_ids: ['id'])
# => ValidationError: batch_id is required and cannot be blank

# Empty exported_ids array
ZaiPayment.batch_transactions.process_to_bank_processing('batch_id', exported_ids: [])
# => ValidationError: exported_ids is required and must be a non-empty array

# Invalid state code
ZaiPayment.batch_transactions.update_transaction_states('batch_id', exported_ids: ['id'], state: 99999)
# => ValidationError: state must be 12700 (bank_processing) or 12000 (successful), got: 99999
```

## Available Methods

### `list(**options)`

List and filter batch transactions.

- **Parameters:**
  - `limit` (Integer): Number of records to return (default: 10, max: 200)
  - `offset` (Integer): Number of records to skip (default: 0)
  - `account_id` (String): Filter by account ID
  - `batch_id` (String): Filter by batch ID
  - `item_id` (String): Filter by item ID
  - `transaction_type` (String): payment, refund, disbursement, fee, deposit, withdrawal
  - `transaction_type_method` (String): credit_card, npp, bpay, wallet_account_transfer, wire_transfer, misc
  - `direction` (String): debit or credit
  - `created_before` (String): ISO 8601 date/time
  - `created_after` (String): ISO 8601 date/time
  - `disbursement_bank` (String): Bank used for disbursing
  - `processing_bank` (String): Bank used for processing
- **Returns:** Response with batch_transactions array
- **Available in:** All environments

### `show(id)`

Get a single batch transaction using its ID.

- **Parameters:**
  - `id` (String): The batch transaction ID (UUID or numeric ID)
- **Returns:** Response with batch_transactions object
- **Raises:** ValidationError if id is blank
- **Available in:** All environments

### `export_transactions`

Exports all pending batch transactions to batched state.

- **Returns:** Response with transactions array containing batch_id
- **Raises:** ConfigurationError if not in prelive environment

### `update_transaction_states(batch_id, exported_ids:, state:)`

Updates batch transaction states to a specific state code.

- **Parameters:**
  - `batch_id` (String): The batch ID from export_transactions
  - `exported_ids` (Array<String>): Array of transaction IDs to update
  - `state` (Integer): Target state code (12700 or 12000)
- **Returns:** Response with exported_ids and state
- **Raises:** ConfigurationError, ValidationError

### `process_to_bank_processing(batch_id, exported_ids:)`

Convenience method to move transactions to bank_processing state (12700).

- **Parameters:**
  - `batch_id` (String): The batch ID from export_transactions
  - `exported_ids` (Array<String>): Array of transaction IDs to update
- **Returns:** Response with exported_ids and state
- **Raises:** ConfigurationError, ValidationError

### `process_to_successful(batch_id, exported_ids:)`

Convenience method to move transactions to successful state (12000).

- **Parameters:**
  - `batch_id` (String): The batch ID from export_transactions
  - `exported_ids` (Array<String>): Array of transaction IDs to update
- **Returns:** Response with exported_ids and state
- **Raises:** ConfigurationError, ValidationError

## Notes

- These endpoints are **only available in the prelive environment**
- Transaction IDs from prelive simulations may be cleared after a day
- The successful state (12000) triggers batch_transactions webhooks
- You must store the `batch_id` from the export_transactions response to use in subsequent calls

