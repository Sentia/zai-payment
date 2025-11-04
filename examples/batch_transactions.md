# Batch Transactions (Prelive Only)

## Overview

The batch transaction endpoints are available **only in the prelive environment** and are used to simulate the batch transaction lifecycle for testing purposes.

These endpoints allow you to:
1. Export pending batch transactions to the "batched" state
2. Move batch transactions to the "bank_processing" state
3. Move batch transactions to the "successful" state (which triggers webhooks)

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

### Step 1: Export Transactions

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

If you need more information on the item, transactions, or batch_transaction, you can query them using their IDs:

```ruby
# Query a specific batch transaction using cURL or direct API call
# GET /batch_transactions/{batch_transaction_id}

# Example cURL:
# curl https://test.api.promisepay.com/batch_transactions/dabcfd50-bf5a-0138-7b40-0a58a9feac03
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

