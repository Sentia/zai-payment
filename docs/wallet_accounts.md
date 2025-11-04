# Wallet Account Management

The WalletAccount resource provides methods for managing Zai wallet accounts for Australian payments and bill payments.

## Overview

Wallet accounts are digital wallets that hold funds and can be used for various payment operations including bill payments via BPay, withdrawals, and other disbursements. Each user in the Zai platform can have a wallet account with a balance that can be topped up and used for payments.

Once created by Zai, store the returned `:id` and use it for payment operations. The wallet account maintains a balance in the specified currency (typically AUD for Australian marketplaces).

## References

- [Wallet Accounts API](https://developer.hellozai.com/reference)
- [Payment Methods Guide](https://developer.hellozai.com/docs/payment-methods)

## Usage

### Initialize the WalletAccount Resource

```ruby
# Using a new instance
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Or use with custom client
client = ZaiPayment::Client.new
wallet_accounts = ZaiPayment::Resources::WalletAccount.new(client: client)
```

## Methods

### Show Wallet Account

Get details of a specific wallet account by ID.

#### Parameters

- `wallet_account_id` (required) - The wallet account ID

#### Example

```ruby
# Get wallet account details
response = wallet_accounts.show('5c1c6b10-4c56-0137-8cd7-0242ac110002')

# Access wallet account details
wallet_account = response.data
puts wallet_account['id']
puts wallet_account['active']
puts wallet_account['balance']
puts wallet_account['currency']
puts wallet_account['created_at']
puts wallet_account['updated_at']

# Access links
links = wallet_account['links']
puts links['users']
puts links['transactions']
puts links['bpay_details']
puts links['npp_details']
```

#### Response

```ruby
{
  "wallet_accounts" => {
    "id" => "5c1c6b10-4c56-0137-8cd7-0242ac110002",
    "active" => true,
    "created_at" => "2019-04-29T02:42:31.536Z",
    "updated_at" => "2020-05-03T12:01:02.254Z",
    "balance" => 663337,
    "currency" => "AUD",
    "links" => {
      "self" => "/transactions/aed45af0-6f63-0138-901c-0a58a9feac03/wallet_accounts",
      "users" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/users",
      "batch_transactions" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/batch_transactions",
      "transactions" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/transactions",
      "bpay_details" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/bpay_details",
      "npp_details" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/npp_details",
      "virtual_accounts" => "/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/virtual_accounts"
    }
  }
}
```

**Use Cases:**
- Check wallet balance before initiating payments
- Verify account status and activity
- Monitor wallet account details
- Access related resources via links

### Show Wallet Account User

Get the User the Wallet Account is associated with using a given wallet_account_id.

#### Parameters

- `wallet_account_id` (required) - The wallet account ID

#### Example

```ruby
# Get user associated with wallet account
response = wallet_accounts.show_user('5c1c6b10-4c56-0137-8cd7-0242ac110002')

# Access user details
user = response.data
puts user['id']
puts user['full_name']
puts user['email']
puts user['verification_state']
puts user['held_state']
```

#### Response

```ruby
{
  "users" => {
    "created_at" => "2020-04-03T07:59:00.379Z",
    "updated_at" => "2020-04-03T07:59:00.379Z",
    "id" => "Seller_1234",
    "full_name" => "Samuel Seller",
    "email" => "sam@example.com",
    "mobile" => 69543131,
    "first_name" => "Samuel",
    "last_name" => "Seller",
    "custom_descriptor" => "Sam Garden Jobs",
    "location" => "AUS",
    "verification_state" => "pending",
    "held_state" => false,
    "roles" => ["customer"],
    "dob" => "encrypted",
    "government_number" => "encrypted",
    "flags" => {},
    "related" => {
      "addresses" => "11111111-2222-3333-4444-55555555555,"
    },
    "links" => {
      "self" => "/wallet_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/users",
      "items" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/items",
      "wallet_accounts" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/wallet_accounts"
    }
  }
}
```

**Use Cases:**
- Retrieve user information for a wallet account
- Verify user identity before payment
- Check user verification status
- Get user contact details for notifications

### Pay a Bill

Pay a bill by withdrawing funds from a Wallet Account to a specified BPay account.

#### Required Fields

- `wallet_account_id` (path parameter) - The wallet account ID to withdraw from
- `account_id` - BPay account ID to withdraw to (must be a valid `bpay_account_id`)
- `amount` - Amount in cents to withdraw (must be a positive integer)

#### Optional Fields

- `reference_id` - Unique reference information for the payment (cannot contain single quote character)

#### Example

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

response = wallet_accounts.pay_bill(
  '901d8cd0-6af3-0138-967d-0a58a9feac04',
  account_id: 'c1824ad0-73f1-0138-3700-0a58a9feac09',
  amount: 173,
  reference_id: 'test100'
)

if response.success?
  disbursement = response.data
  puts "Disbursement ID: #{disbursement['id']}"
  puts "Amount: #{disbursement['amount']}"
  puts "State: #{disbursement['state']}"
  puts "Reference: #{disbursement['reference_id']}"
  puts "To: #{disbursement['to']}"
  puts "Account Name: #{disbursement['account_name']}"
  puts "Biller Name: #{disbursement['biller_name']}"
  puts "Biller Code: #{disbursement['biller_code']}"
  puts "CRN: #{disbursement['crn']}"
end
```

#### Response

```ruby
{
  "disbursements" => {
    "reference_id" => "test100",
    "id" => "8a31ebfa-421b-4cbb-9241-632f71b3778a",
    "amount" => 173,
    "currency" => "AUD",
    "created_at" => "2020-05-09T07:09:03.383Z",
    "updated_at" => "2020-05-09T07:09:04.585Z",
    "state" => "pending",
    "to" => "BPay Account",
    "account_name" => "My Water Company",
    "biller_name" => "ABC Water",
    "biller_code" => 123456,
    "crn" => "0987654321",
    "links" => {
      "transactions" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/transactions",
      "wallet_accounts" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/wallet_accounts",
      "bank_accounts" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/bank_accounts",
      "bpay_accounts" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/bpay_accounts",
      "paypal_accounts" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/paypal_accounts",
      "items" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/items",
      "users" => "/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/users"
    }
  }
}
```

**Important Notes:**
- Amount is in cents (e.g., 173 = $1.73 AUD)
- The wallet must have sufficient balance to cover the payment
- Disbursement state will be "pending" initially, then transitions to "successful" or "failed"
- Reference ID is optional but recommended for tracking purposes

## Validation Rules

### Wallet Account ID

- Required for all methods
- Must not be blank or nil
- Must be a valid UUID format

### Amount (for pay_bill)

- Required field
- Must be a positive integer
- Specified in cents (e.g., 100 = $1.00)
- Must not exceed wallet balance

### Account ID (for pay_bill)

- Required field
- Must be a valid BPay account ID
- The BPay account must be active and verified

### Reference ID (for pay_bill)

- Optional field
- Cannot contain single quote (') character
- Used for tracking and reconciliation
- Should be unique for each payment

## Error Handling

The WalletAccount resource raises the following errors:

### NotFoundError

Raised when the wallet account does not exist:

```ruby
begin
  wallet_accounts.show('invalid_id')
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Wallet account not found: #{e.message}"
end
```

### ValidationError

Raised when required fields are missing or invalid:

```ruby
begin
  wallet_accounts.pay_bill(
    '901d8cd0-6af3-0138-967d-0a58a9feac04',
    account_id: 'test123'
    # Missing required field: amount
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # => "Missing required fields: amount"
end
```

### Invalid Amount

```ruby
begin
  wallet_accounts.pay_bill(
    '901d8cd0-6af3-0138-967d-0a58a9feac04',
    account_id: 'bpay_account_123',
    amount: -100  # Negative amount
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "amount must be a positive integer"
end
```

### Invalid Reference ID

```ruby
begin
  wallet_accounts.pay_bill(
    '901d8cd0-6af3-0138-967d-0a58a9feac04',
    account_id: 'bpay_account_123',
    amount: 173,
    reference_id: "test'100"  # Contains single quote
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "reference_id cannot contain single quote (') character"
end
```

### Blank Wallet Account ID

```ruby
begin
  wallet_accounts.show('')
  # or
  wallet_accounts.pay_bill(nil, account_id: 'test', amount: 100)
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid ID: #{e.message}"
  # => "wallet_account_id is required and cannot be blank"
end
```

## Use Cases

### Use Case 1: Check Balance Before Payment

Check wallet balance before initiating a bill payment:

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Step 1: Check wallet balance
response = wallet_accounts.show('wallet_account_id')

if response.success?
  wallet = response.data
  balance = wallet['balance']  # in cents
  
  # Step 2: Verify sufficient funds
  payment_amount = 17300  # $173.00
  
  if balance >= payment_amount
    puts "Sufficient balance: $#{balance / 100.0}"
    
    # Step 3: Process payment
    payment_response = wallet_accounts.pay_bill(
      'wallet_account_id',
      account_id: 'bpay_account_id',
      amount: payment_amount,
      reference_id: 'bill_#{Time.now.to_i}'
    )
    
    puts "Payment initiated" if payment_response.success?
  else
    puts "Insufficient funds: $#{balance / 100.0} < $#{payment_amount / 100.0}"
  end
end
```

### Use Case 2: Pay Multiple Bills

Process multiple bill payments from a wallet account:

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new
wallet_id = '901d8cd0-6af3-0138-967d-0a58a9feac04'

bills = [
  { account_id: 'bpay_water', amount: 15000, ref: 'water_202411' },
  { account_id: 'bpay_electricity', amount: 22000, ref: 'elec_202411' },
  { account_id: 'bpay_gas', amount: 8500, ref: 'gas_202411' }
]

bills.each do |bill|
  response = wallet_accounts.pay_bill(
    wallet_id,
    account_id: bill[:account_id],
    amount: bill[:amount],
    reference_id: bill[:ref]
  )
  
  if response.success?
    puts "Paid #{bill[:ref]}: $#{bill[:amount] / 100.0}"
  else
    puts "Failed to pay #{bill[:ref]}"
  end
end
```

### Use Case 3: Get User Details for Wallet Account

Retrieve user information for notification purposes:

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Step 1: Get user details
user_response = wallet_accounts.show_user('wallet_account_id')

if user_response.success?
  user = user_response.data
  
  # Step 2: Verify user eligibility
  if user['verification_state'] == 'verified' && !user['held_state']
    puts "User verified: #{user['full_name']}"
    puts "Email: #{user['email']}"
    
    # Step 3: Send notification
    # NotificationService.send_payment_confirmation(user['email'])
  else
    puts "User not eligible for payments"
    puts "Verification: #{user['verification_state']}"
    puts "On Hold: #{user['held_state']}"
  end
end
```

### Use Case 4: Monitor Disbursement Status

Track the status of a bill payment:

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Initiate payment
payment_response = wallet_accounts.pay_bill(
  'wallet_account_id',
  account_id: 'bpay_account_id',
  amount: 17300,
  reference_id: 'bill_123'
)

if payment_response.success?
  disbursement = payment_response.data
  disbursement_id = disbursement['id']
  
  puts "Payment initiated: #{disbursement_id}"
  puts "State: #{disbursement['state']}"
  puts "To: #{disbursement['account_name']}"
  puts "Biller: #{disbursement['biller_name']}"
  
  # Monitor using disbursement ID
  # Later check status via transactions or webhooks
end
```

## Important Notes

1. **Currency**: Wallet accounts typically use AUD (Australian Dollars) for Australian marketplaces
2. **Balance**: The balance is returned in cents (e.g., 663337 = $6,633.37)
3. **Payment Amount**: Amounts must be specified in cents
4. **BPay Integration**: The `pay_bill` method integrates with BPay for Australian bill payments
5. **Disbursement State**: Payment states include `pending`, `successful`, and `failed`
6. **Reference Tracking**: Use `reference_id` for payment tracking and reconciliation
7. **Sufficient Funds**: Ensure wallet has sufficient balance before initiating payments
8. **Account Status**: Only active wallet accounts can be used for payments

## Disbursement States

- **pending**: Payment has been initiated but not yet processed
- **successful**: Payment completed successfully
- **failed**: Payment failed (check error details)

Monitor payment status through:
- Webhook notifications
- Transaction queries
- Disbursement status checks

## Related Resources

- [User Management](users.md) - Creating and managing users
- [BPay Accounts](bpay_accounts.md) - Managing BPay accounts for bill payments
- [Items](items.md) - Creating items for payments

## Further Reading

- [Payment Methods Guide](https://developer.hellozai.com/docs/payment-methods)
- [Wallet Account API Reference](https://developer.hellozai.com/reference)
- [BPay Overview](https://developer.hellozai.com/docs/bpay)
- [Verification Process](https://developer.hellozai.com/docs/verification)

