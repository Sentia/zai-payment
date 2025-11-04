# Batch Transactions (Prelive Only)

## Overview

The Batch Transaction resource provides methods to simulate batch transaction processing in the prelive environment. These endpoints are designed for testing and allow you to move transactions through different states of the batch processing lifecycle.

**Important:** These endpoints are only available when the gem is configured for the `:prelive` environment. Attempting to use them in production will raise a `ConfigurationError`.

## When to Use

Use the batch transaction endpoints when you need to:

1. Test the full lifecycle of batch transaction processing
2. Simulate bank processing states in your test environment
3. Trigger batch transaction webhooks for testing webhook handlers
4. Verify your application's handling of different batch transaction states

## Authentication & Configuration

Ensure your configuration uses the prelive environment:

```ruby
ZaiPayment.configure do |config|
  config.environment = :prelive  # Required!
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.scope = 'your_scope'
end
```

## Resource Access

Access the batch transaction resource through the main module:

```ruby
batch_transactions = ZaiPayment.batch_transactions
```

## The Batch Transaction Lifecycle

In prelive, batch transactions go through these states:

1. **pending** → Initial state when a batch transaction is created
2. **batched** → Transactions grouped into a batch (via `export_transactions`)
3. **bank_processing** (state 12700) → Batch is being processed by the bank
4. **successful** (state 12000) → Processing complete, webhook triggered

## Method Reference

### `export_transactions`

Moves all pending batch transactions to the "batched" state and returns them with their assigned `batch_id`.

**Signature:**
```ruby
export_transactions() → Response
```

**Returns:**
- `Response` object with transactions array
- Each transaction includes: `id`, `batch_id`, `status`, `type`, `type_method`

**Raises:**
- `ConfigurationError` - if not in prelive environment

**Example:**
```ruby
response = ZaiPayment.batch_transactions.export_transactions

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
```

**Note:** Store the returned `batch_id` - you'll need it for the next steps. Transaction IDs may be cleared after 24 hours in prelive.

---

### `update_transaction_states`

Updates the state of one or more batch transactions within a batch.

**Signature:**
```ruby
update_transaction_states(batch_id, exported_ids:, state:) → Response
```

**Parameters:**
- `batch_id` (String) - The batch ID from `export_transactions` response
- `exported_ids` (Array<String>) - Array of transaction IDs to update
- `state` (Integer) - Target state code: `12700` (bank_processing) or `12000` (successful)

**Returns:**
- `Response` object with `aggregated_jobs_uuid`, `msg`, and `errors` array

**Raises:**
- `ConfigurationError` - if not in prelive environment
- `ValidationError` - if batch_id is blank
- `ValidationError` - if exported_ids is nil, empty, not an array, or contains nil/empty values
- `ValidationError` - if state is not 12700 or 12000

**Example:**
```ruby
response = ZaiPayment.batch_transactions.update_transaction_states(
  'batch_id',
  exported_ids: ['439970a2-e0a1-418e-aecf-6b519c115c55'],
  state: 12700
)

response.body
# => {
#   "aggregated_jobs_uuid" => "c1cbc502-9754-42fd-9731-2330ddd7a41f",
#   "msg" => "1 jobs have been sent to the queue.",
#   "errors" => []
# }
```

---

### `process_to_bank_processing`

Convenience method to move transactions to the "bank_processing" state (12700).

**Signature:**
```ruby
process_to_bank_processing(batch_id, exported_ids:) → Response
```

**Parameters:**
- `batch_id` (String) - The batch ID from `export_transactions` response
- `exported_ids` (Array<String>) - Array of transaction IDs to update

**Returns:**
- `Response` object with `aggregated_jobs_uuid`, `msg`, and `errors` (12700)

**Raises:**
- Same as `update_transaction_states`

**Example:**
```ruby
response = ZaiPayment.batch_transactions.process_to_bank_processing(
  'batch_id',
  exported_ids: ['transaction_id_1', 'transaction_id_2']
)
```

**Note:** This is equivalent to calling `update_transaction_states` with `state: 12700`.

---

### `process_to_successful`

Convenience method to move transactions to the "successful" state (12000). This triggers batch transaction webhooks.

**Signature:**
```ruby
process_to_successful(batch_id, exported_ids:) → Response
```

**Parameters:**
- `batch_id` (String) - The batch ID from `export_transactions` response
- `exported_ids` (Array<String>) - Array of transaction IDs to update

**Returns:**
- `Response` object with `aggregated_jobs_uuid`, `msg`, and `errors` (12000)

**Raises:**
- Same as `update_transaction_states`

**Example:**
```ruby
response = ZaiPayment.batch_transactions.process_to_successful(
  'batch_id',
  exported_ids: ['transaction_id_1']
)

# This will trigger a batch_transactions webhook
```

**Note:** This is equivalent to calling `update_transaction_states` with `state: 12000`.

---

## Complete Workflow Example

Here's the typical workflow for testing batch transactions in prelive:

```ruby
# Step 1: Export pending transactions
export_response = ZaiPayment.batch_transactions.export_transactions

batch_id = export_response.data.first['batch_id']
transaction_ids = export_response.data.map { |t| t['id'] }

puts "Exported #{transaction_ids.length} transactions to batch #{batch_id}"

# Step 2: Move to bank_processing state
processing_response = ZaiPayment.batch_transactions.process_to_bank_processing(
  batch_id,
  exported_ids: transaction_ids
)

puts "Transactions moved to bank_processing (12700)"

# Step 3: Move to successful state (triggers webhook)
success_response = ZaiPayment.batch_transactions.process_to_successful(
  batch_id,
  exported_ids: transaction_ids
)

puts "Transactions completed successfully (12000)"
puts "Webhook should now be triggered"
```

## State Codes

| Code | State | Description |
|------|-------|-------------|
| 12700 | bank_processing | Transactions are being processed by the bank |
| 12000 | successful | Final state - processing complete, webhooks triggered |

## Error Handling

### ConfigurationError

Raised when attempting to use batch transaction endpoints outside of prelive:

```ruby
ZaiPayment.configure do |config|
  config.environment = :production  # Wrong environment!
end

begin
  ZaiPayment.batch_transactions.export_transactions
rescue ZaiPayment::Errors::ConfigurationError => e
  puts e.message
  # => "Batch transaction endpoints are only available in prelive environment. 
  #     Current environment: production"
end
```

### ValidationError

Raised when parameters are invalid:

```ruby
# Blank batch_id
ZaiPayment.batch_transactions.process_to_bank_processing(
  '',
  exported_ids: ['id']
)
# => ValidationError: batch_id is required and cannot be blank

# Empty exported_ids
ZaiPayment.batch_transactions.process_to_bank_processing(
  'batch_id',
  exported_ids: []
)
# => ValidationError: exported_ids is required and must be a non-empty array

# exported_ids contains nil
ZaiPayment.batch_transactions.process_to_bank_processing(
  'batch_id',
  exported_ids: ['valid_id', nil]
)
# => ValidationError: exported_ids cannot contain nil or empty values

# Invalid state code
ZaiPayment.batch_transactions.update_transaction_states(
  'batch_id',
  exported_ids: ['id'],
  state: 99999
)
# => ValidationError: state must be 12700 (bank_processing) or 12000 (successful), got: 99999
```

## Testing Webhooks

The `process_to_successful` method triggers batch transaction webhooks, allowing you to test your webhook handlers:

```ruby
# Set up webhook handler to receive batch_transactions events
# Then complete the batch transaction flow:

export_response = ZaiPayment.batch_transactions.export_transactions
batch_id = export_response.data.first['batch_id']
transaction_ids = export_response.data.map { |t| t['id'] }

# Process through states
ZaiPayment.batch_transactions.process_to_bank_processing(batch_id, exported_ids: transaction_ids)
ZaiPayment.batch_transactions.process_to_successful(batch_id, exported_ids: transaction_ids)

# Your webhook handler should now receive the batch_transactions webhook
```

## Querying Batch Transactions

After exporting and processing transactions, you can query them using the item's transaction endpoints:

```ruby
# List transactions for an item
item_id = 'your_item_id'
response = ZaiPayment.items.list_transactions(item_id)

# List batch transactions for an item
response = ZaiPayment.items.list_batch_transactions(item_id)
```

You can also query batch transactions directly via the API using cURL:

```bash
curl https://test.api.promisepay.com/batch_transactions/dabcfd50-bf5a-0138-7b40-0a58a9feac03 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Important Notes

1. **Prelive Only**: These endpoints only work in prelive environment
2. **24-Hour Limit**: Transaction IDs may be cleared after 24 hours in prelive
3. **Webhook Trigger**: Only the successful state (12000) triggers webhooks
4. **Batch ID Required**: You must save the `batch_id` from `export_transactions` for subsequent calls
5. **Array Support**: You can process multiple transactions at once by passing multiple IDs

## Related Resources

- [Items](./items.md) - For creating items that generate transactions
- [Webhooks](./webhooks.md) - For handling batch transaction webhooks
- [Webhook Security](./webhook_security_quickstart.md) - For securing your webhook endpoints

## API Reference

For more details on the underlying API endpoints, see the [Zai API Documentation](https://developer.hellozai.com/reference).

