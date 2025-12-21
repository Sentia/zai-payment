# Batch Transactions API Response Correction

## Response Format for PATCH /batches/:id/transaction_states

### ✅ Correct Response Format

The actual API response for `PATCH /batches/:id/transaction_states` contains:

```json
{
  "aggregated_jobs_uuid": "c1cbc502-9754-42fd-9731-2330ddd7a41f",
  "msg": "1 jobs have been sent to the queue.",
  "errors": []
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `aggregated_jobs_uuid` | String | UUID identifying the batch of jobs sent to the queue |
| `msg` | String | Success message indicating how many jobs were queued |
| `errors` | Array | Array of any errors (typically empty on success) |

### Ruby Usage Example

```ruby
response = ZaiPayment.batch_transactions.update_transaction_states(
  'batch_id',
  exported_ids: ['439970a2-e0a1-418e-aecf-6b519c115c55'],
  state: 12700
)

# Access response data
response.body['aggregated_jobs_uuid'] # => "c1cbc502-9754-42fd-9731-2330ddd7a41f"
response.body['msg']                   # => "1 jobs have been sent to the queue."
response.body['errors']                # => []

# Check for success
if response.success? && response.body['errors'].empty?
  puts "Successfully queued #{response.body['msg']}"
  puts "Job UUID: #{response.body['aggregated_jobs_uuid']}"
end
```

### Multiple Transactions

When processing multiple transactions, the message reflects the count:

```ruby
response = ZaiPayment.batch_transactions.update_transaction_states(
  'batch_id',
  exported_ids: ['id1', 'id2', 'id3'],
  state: 12000
)

response.body['msg'] # => "3 jobs have been sent to the queue."
```

## Updated Files

All documentation and specs have been updated to reflect the correct response format:

1. ✅ `lib/zai_payment/resources/batch_transaction.rb` - YARD documentation
2. ✅ `spec/zai_payment/resources/batch_transaction_spec.rb` - Test expectations
3. ✅ `examples/batch_transactions.md` - Example code
4. ✅ `docs/batch_transactions.md` - Technical documentation

## Key Points

- The response is **asynchronous** - jobs are queued for processing
- The `aggregated_jobs_uuid` can be used to track the batch of jobs
- Check the `errors` array to ensure no errors occurred
- The `msg` field contains a human-readable description of what was queued

