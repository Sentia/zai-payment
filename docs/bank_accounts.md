# Bank Account Management

The BankAccount resource provides methods for managing Zai bank accounts for both Australian and UK regions.

## Overview

Bank accounts are used as either a funding source or a disbursement destination. Once created, store the returned `:id` and use it for a `make_payment` Item Action call. The `:id` is also referred to as a `:token` when invoking Bank Accounts.

For platforms operating in the UK, `iban` and `swift_code` are extra required fields in addition to the standard Australian fields.

## References

- [Create Bank Account API](https://developer.hellozai.com/reference/createbankaccount)
- [Bank Account Formats by Country](https://developer.hellozai.com/docs/bank-account-formats)

## Usage

### Initialize the BankAccount Resource

```ruby
# Using a new instance
bank_accounts = ZaiPayment::Resources::BankAccount.new

# Or use with custom client
client = ZaiPayment::Client.new
bank_accounts = ZaiPayment::Resources::BankAccount.new(client: client)
```

## Methods

### Create Australian Bank Account

Create a new bank account for an Australian user.

#### Required Fields

- `user_id` - User ID (defaults to aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee)
- `bank_name` - Bank name (defaults to Bank of Australia)
- `account_name` - Account name (defaults to Samuel Seller)
- `routing_number` - Routing number / BSB number (defaults to 111123). See [Bank account formats by country](https://developer.hellozai.com/docs/bank-account-formats).
- `account_number` - Account number (defaults to 111234). See [Bank account formats by country](https://developer.hellozai.com/docs/bank-account-formats).
- `account_type` - Bank account type ('savings' or 'checking', defaults to checking)
- `holder_type` - Holder type ('personal' or 'business', defaults to personal)
- `country` - ISO 3166-1 alpha-3 country code (length ≤ 3, defaults to AUS)

#### Optional Fields

- `payout_currency` - ISO 4217 alpha-3 currency code for payouts
- `currency` - ISO 4217 alpha-3 currency code. This is an optional field and if not provided, the item will be created with the default currency of the marketplace.

#### Example

```ruby
response = bank_accounts.create_au(
  user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  bank_name: 'Bank of Australia',
  account_name: 'Samuel Seller',
  routing_number: '111123',
  account_number: '111234',
  account_type: 'checking',
  holder_type: 'personal',
  country: 'AUS',
  payout_currency: 'AUD',
  currency: 'AUD'
)

if response.success?
  bank_account = response.data
  puts "Bank Account ID: #{bank_account['id']}"
  puts "Active: #{bank_account['active']}"
  puts "Verification Status: #{bank_account['verification_status']}"
  puts "Currency: #{bank_account['currency']}"
  
  # Access bank details
  bank = bank_account['bank']
  puts "Bank Name: #{bank['bank_name']}"
  puts "Account Name: #{bank['account_name']}"
  puts "Account Type: #{bank['account_type']}"
  puts "Holder Type: #{bank['holder_type']}"
  puts "Routing Number: #{bank['routing_number']}"
  puts "Direct Debit Status: #{bank['direct_debit_authority_status']}"
  
  # Access links
  links = bank_account['links']
  puts "Self Link: #{links['self']}"
  puts "Users Link: #{links['users']}"
end
```

### Create UK Bank Account

Create a new bank account for a UK user. UK bank accounts require additional fields: `iban` and `swift_code`.

#### Required Fields

All fields from Australian bank accounts plus:

- `iban` - International Bank Account Number (required for UK)
- `swift_code` - SWIFT Code / BIC (required for UK)

#### Example

```ruby
response = bank_accounts.create_uk(
  user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  bank_name: 'Bank of UK',
  account_name: 'Samuel Seller',
  routing_number: '111123',
  account_number: '111234',
  account_type: 'checking',
  holder_type: 'personal',
  country: 'GBR',
  iban: 'GB25QHWM02498765432109',
  swift_code: 'BUKBGB22',
  payout_currency: 'GBP',
  currency: 'GBP'
)

if response.success?
  bank_account = response.data
  puts "Bank Account ID: #{bank_account['id']}"
  
  bank = bank_account['bank']
  puts "IBAN: #{bank['iban']}"
  puts "SWIFT Code: #{bank['swift_code']}"
end
```

## Response Structure

Both methods return a `ZaiPayment::Response` object with the following structure:

```ruby
{
  "bank_accounts" => {
    "id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "active" => true,
    "verification_status" => "not_verified",
    "currency" => "AUD",
    "bank" => {
      "bank_name" => "Bank of Australia",
      "country" => "AUS",
      "account_name" => "Samuel Seller",
      "routing_number" => "XXXXX3",      # Masked for security
      "account_number" => "XXX234",      # Masked for security
      "iban" => "null,",                 # Or actual IBAN for UK
      "swift_code" => "null,",           # Or actual SWIFT for UK
      "holder_type" => "personal",
      "account_type" => "checking",
      "direct_debit_authority_status" => "approved"
    },
    "links" => {
      "self" => "/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "users" => "/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users",
      "direct_debit_authorities" => "/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/direct_debit_authorities"
    }
  }
}
```

## Validation Rules

### Account Type

Must be one of:
- `savings` - Savings account
- `checking` - Checking/current account

### Holder Type

Must be one of:
- `personal` - Personal/individual account
- `business` - Business/company account

### Country Code

Must be a valid ISO 3166-1 alpha-3 code (3 letters):
- Australia: `AUS`
- United Kingdom: `GBR`

### Currency Code

When provided, must be a valid ISO 4217 alpha-3 code:
- Australian Dollar: `AUD`
- British Pound: `GBP`
- US Dollar: `USD`

## Error Handling

The BankAccount resource raises the following errors:

### ValidationError

Raised when required fields are missing or invalid:

```ruby
begin
  bank_accounts.create_au(
    user_id: 'user_123',
    bank_name: 'Test Bank'
    # Missing required fields
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # => "Missing required fields: account_name, routing_number, account_number, account_type, holder_type, country"
end
```

### Invalid Account Type

```ruby
begin
  bank_accounts.create_au(
    user_id: 'user_123',
    bank_name: 'Test Bank',
    account_name: 'Test',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'invalid',
    holder_type: 'personal',
    country: 'AUS'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "account_type must be one of: savings, checking"
end
```

### Invalid Holder Type

```ruby
begin
  bank_accounts.create_au(
    user_id: 'user_123',
    bank_name: 'Test Bank',
    account_name: 'Test',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'checking',
    holder_type: 'invalid',
    country: 'AUS'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "holder_type must be one of: personal, business"
end
```

### Invalid Country Code

```ruby
begin
  bank_accounts.create_au(
    user_id: 'user_123',
    bank_name: 'Test Bank',
    account_name: 'Test',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'checking',
    holder_type: 'personal',
    country: 'INVALID'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "country must be a valid ISO 3166-1 alpha-3 code (e.g., AUS, GBR)"
end
```

## Use Cases

### Use Case 1: Disbursement Account Setup

After creating a payout user (seller), create a bank account for receiving payments:

```ruby
# Step 1: Create payout user
users = ZaiPayment::Resources::User.new
user_response = users.create(
  user_type: 'payout',
  email: 'seller@example.com',
  first_name: 'Jane',
  last_name: 'Seller',
  country: 'AUS',
  dob: '01/01/1990',
  address_line1: '123 Main St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000'
)

user_id = user_response.data['id']

# Step 2: Create bank account
bank_accounts = ZaiPayment::Resources::BankAccount.new
bank_response = bank_accounts.create_au(
  user_id: user_id,
  bank_name: 'Commonwealth Bank',
  account_name: 'Jane Seller',
  routing_number: '062000',
  account_number: '12345678',
  account_type: 'savings',
  holder_type: 'personal',
  country: 'AUS',
  payout_currency: 'AUD'
)

account_id = bank_response.data['id']

# Step 3: Set as disbursement account
users.set_disbursement_account(user_id, account_id)
```

### Use Case 2: Multi-Currency Business Account

Create business bank accounts for different currencies:

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

# Australian business account
au_response = bank_accounts.create_au(
  user_id: 'business_user_123',
  bank_name: 'Westpac',
  account_name: 'ABC Pty Ltd',
  routing_number: '032000',
  account_number: '87654321',
  account_type: 'checking',
  holder_type: 'business',
  country: 'AUS',
  payout_currency: 'AUD'
)

# UK business account
uk_response = bank_accounts.create_uk(
  user_id: 'business_user_123',
  bank_name: 'Barclays',
  account_name: 'ABC Limited',
  routing_number: '200000',
  account_number: '55779911',
  account_type: 'checking',
  holder_type: 'business',
  country: 'GBR',
  iban: 'GB33BUKB20000055779911',
  swift_code: 'BARCGB22',
  payout_currency: 'GBP'
)
```

## Important Notes

1. **Security**: Account numbers and routing numbers are masked in API responses for security
2. **Verification**: New bank accounts typically have `verification_status: "not_verified"` until verified by Zai
3. **Direct Debit**: The `direct_debit_authority_status` indicates if direct debit is available for the account
4. **Token Usage**: The returned `id` can be used as a token for payment operations
5. **Region Differences**:
   - Australia: Only requires standard banking details
   - UK: Additionally requires IBAN and SWIFT code

## Related Resources

- [User Management](users.md) - Creating and managing users
- [Item Management](items.md) - Creating transactions/payments
- [Disbursement Accounts](users.md#set-disbursement-account) - Setting default payout accounts

## Further Reading

- [Bank Account Formats by Country](https://developer.hellozai.com/docs/bank-account-formats)
- [Payment Methods Guide](https://developer.hellozai.com/docs/payment-methods)
- [Verification Process](https://developer.hellozai.com/docs/verification)

