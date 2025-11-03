# Bank Account Management Examples

This document provides practical examples for managing bank accounts in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Show Bank Account Example](#show-bank-account-example)
- [Redact Bank Account Example](#redact-bank-account-example)
- [Australian Bank Account Examples](#australian-bank-account-examples)
- [UK Bank Account Examples](#uk-bank-account-examples)
- [Common Patterns](#common-patterns)

## Setup

```ruby
require 'zai_payment'

# Configure ZaiPayment
ZaiPayment.configure do |config|
  config.environment = :prelive  # or :production
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end
```

## Show Bank Account Example

### Example 1: Get Bank Account Details

Retrieve details of a specific bank account.

```ruby
# Get bank account details
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.show('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

if response.success?
  bank_account = response.data
  puts "Bank Account ID: #{bank_account['id']}"
  puts "Active: #{bank_account['active']}"
  puts "Verification Status: #{bank_account['verification_status']}"
  puts "Currency: #{bank_account['currency']}"
  
  # Access bank details (numbers are masked by default)
  bank = bank_account['bank']
  puts "\nBank Details:"
  puts "  Bank Name: #{bank['bank_name']}"
  puts "  Country: #{bank['country']}"
  puts "  Account Name: #{bank['account_name']}"
  puts "  Account Type: #{bank['account_type']}"
  puts "  Holder Type: #{bank['holder_type']}"
  puts "  Account Number: #{bank['account_number']}"  # => "XXX234" (masked)
  puts "  Routing Number: #{bank['routing_number']}"  # => "XXXXX3" (masked)
  puts "  Direct Debit Status: #{bank['direct_debit_authority_status']}"
  
  # Access links
  links = bank_account['links']
  puts "\nLinks:"
  puts "  Self: #{links['self']}"
  puts "  Users: #{links['users']}"
else
  puts "Failed to retrieve bank account"
  puts "Error: #{response.error}"
end
```

### Example 2: Get Bank Account with Decrypted Fields

Retrieve full, unmasked bank account details for secure operations.

```ruby
# Get bank account details with decrypted fields
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.show('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 
                               include_decrypted_fields: true)

if response.success?
  bank_account = response.data
  bank = bank_account['bank']
  
  puts "Bank Account Details (Decrypted):"
  puts "  Account Name: #{bank['account_name']}"
  puts "  Full Account Number: #{bank['account_number']}"  # => "12345678" (full number)
  puts "  Full Routing Number: #{bank['routing_number']}"  # => "111123" (full number)
  
  # Important: Handle decrypted data securely
  # - Don't log in production
  # - Don't store in logs
  # - Use for immediate processing only
else
  puts "Failed to retrieve bank account"
end
```

## Redact Bank Account Example

### Example 9: Redact a Bank Account

Redact (deactivate) a bank account so it can no longer be used.

```ruby
# Redact a bank account
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.redact('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

if response.success?
  puts "Bank account successfully redacted"
  puts "Response: #{response.data}"
  # => {"bank_account"=>"Successfully redacted"}
  
  # The bank account can no longer be used for:
  # - Funding source for payments
  # - Disbursement destination
else
  puts "Failed to redact bank account"
  puts "Error: #{response.error}"
end
```

### Example 10: Redact with Error Handling

Handle edge cases when redacting a bank account.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

begin
  # Attempt to redact the bank account
  response = bank_accounts.redact('bank_account_id_here')
  
  if response.success?
    puts "Bank account redacted successfully"
    
    # Log the action for audit purposes
    Rails.logger.info("Bank account #{bank_account_id} was redacted at #{Time.now}")
  else
    puts "Redaction failed: #{response.error}"
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Bank account not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid bank account ID: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error occurred: #{e.message}"
end
```

## Australian Bank Account Examples

### Example 1: Create Basic Australian Bank Account

Create a bank account for an Australian user with personal account details.

```ruby
# Create an Australian bank account
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_au(
  user_id: 'user_abc123',
  bank_name: 'Bank of Australia',
  account_name: 'Samuel Seller',
  routing_number: '111123',  # BSB number
  account_number: '111234',
  account_type: 'checking',
  holder_type: 'personal',
  country: 'AUS'
)

if response.success?
  bank_account = response.data
  puts "Bank account created successfully!"
  puts "Account ID: #{bank_account['id']}"
  puts "Verification Status: #{bank_account['verification_status']}"
  puts "Account Name: #{bank_account['bank']['account_name']}"
else
  puts "Failed to create bank account"
  puts "Error: #{response.error}"
end
```

### Example 4: Australian Business Bank Account

Create a business bank account for an Australian company.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_au(
  user_id: 'user_company456',
  bank_name: 'Commonwealth Bank',
  account_name: 'ABC Company Pty Ltd',
  routing_number: '062000',  # BSB for Commonwealth Bank
  account_number: '12345678',
  account_type: 'checking',
  holder_type: 'business',  # Business account
  country: 'AUS',
  payout_currency: 'AUD'
)

if response.success?
  bank_account = response.data
  puts "Business bank account created: #{bank_account['id']}"
  puts "Holder Type: #{bank_account['bank']['holder_type']}"
  puts "Direct Debit Status: #{bank_account['bank']['direct_debit_authority_status']}"
end
```

### Example 5: Australian Savings Account

Create a savings account for disbursements.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_au(
  user_id: 'user_saver789',
  bank_name: 'National Australia Bank',
  account_name: 'John Savings',
  routing_number: '083000',  # NAB BSB
  account_number: '87654321',
  account_type: 'savings',  # Savings account
  holder_type: 'personal',
  country: 'AUS',
  payout_currency: 'AUD',
  currency: 'AUD'
)

if response.success?
  bank_account = response.data
  puts "Savings account created: #{bank_account['id']}"
  puts "Currency: #{bank_account['currency']}"
end
```

## UK Bank Account Examples

### Example 6: Create Basic UK Bank Account

Create a bank account for a UK user with IBAN and SWIFT code.

```ruby
# Create a UK bank account
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_uk(
  user_id: 'user_uk123',
  bank_name: 'Bank of UK',
  account_name: 'Samuel Seller',
  routing_number: '111123',  # Sort code
  account_number: '111234',
  account_type: 'checking',
  holder_type: 'personal',
  country: 'GBR',
  iban: 'GB25QHWM02498765432109',  # Required for UK
  swift_code: 'BUKBGB22'  # Required for UK
)

if response.success?
  bank_account = response.data
  puts "UK bank account created successfully!"
  puts "Account ID: #{bank_account['id']}"
  puts "IBAN: #{bank_account['bank']['iban']}"
  puts "SWIFT: #{bank_account['bank']['swift_code']}"
else
  puts "Failed to create UK bank account"
  puts "Error: #{response.error}"
end
```

### Example 7: UK Business Bank Account

Create a business bank account for a UK company with full details.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_uk(
  user_id: 'user_uk_company456',
  bank_name: 'Barclays Bank',
  account_name: 'XYZ Limited',
  routing_number: '200000',  # Barclays sort code
  account_number: '55779911',
  account_type: 'checking',
  holder_type: 'business',
  country: 'GBR',
  iban: 'GB33BUKB20000055779911',
  swift_code: 'BARCGB22',
  payout_currency: 'GBP',
  currency: 'GBP'
)

if response.success?
  bank_account = response.data
  puts "UK business account created: #{bank_account['id']}"
  puts "Bank Name: #{bank_account['bank']['bank_name']}"
  puts "Currency: #{bank_account['currency']}"
end
```

### Example 8: UK Savings Account with Full Details

Create a UK savings account with all available information.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

response = bank_accounts.create_uk(
  user_id: 'user_uk_saver789',
  bank_name: 'HSBC UK Bank',
  account_name: 'Jane Smith',
  routing_number: '400000',
  account_number: '12345678',
  account_type: 'savings',
  holder_type: 'personal',
  country: 'GBR',
  iban: 'GB82HBUK40000012345678',
  swift_code: 'HBUKGB4B',
  payout_currency: 'GBP',
  currency: 'GBP'
)

if response.success?
  bank_account = response.data
  puts "UK savings account created: #{bank_account['id']}"
  puts "Active: #{bank_account['active']}"
  puts "Verification Status: #{bank_account['verification_status']}"
end
```

## Common Patterns

### Pattern 1: Creating Bank Account After User Registration

Typical workflow when onboarding a seller.

```ruby
# Step 1: Create a payout user (seller)
users = ZaiPayment::Resources::User.new

user_response = users.create(
  user_type: 'payout',
  email: 'seller@example.com',
  first_name: 'Sarah',
  last_name: 'Seller',
  country: 'AUS',
  dob: '15/01/1990',
  address_line1: '123 Market St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000',
  mobile: '+61412345678'
)

user_id = user_response.data['id']
puts "User created: #{user_id}"

# Step 2: Create bank account for the seller
bank_accounts = ZaiPayment::Resources::BankAccount.new

bank_response = bank_accounts.create_au(
  user_id: user_id,
  bank_name: 'Bank of Australia',
  account_name: 'Sarah Seller',
  routing_number: '111123',
  account_number: '111234',
  account_type: 'checking',
  holder_type: 'personal',
  country: 'AUS',
  payout_currency: 'AUD'
)

if bank_response.success?
  bank_account_id = bank_response.data['id']
  puts "Bank account created: #{bank_account_id}"
  
  # Step 3: Set as disbursement account
  users.set_disbursement_account(user_id, bank_account_id)
  puts "Disbursement account set successfully"
end
```

### Pattern 2: Error Handling

Handle validation errors when creating bank accounts.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

begin
  response = bank_accounts.create_au(
    user_id: 'user_123',
    bank_name: 'Test Bank',
    account_name: 'Test User',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'invalid_type',  # This will cause an error
    holder_type: 'personal',
    country: 'AUS'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
  puts "Status code: #{e.status_code}"
end
```

### Pattern 3: Multi-Region Setup

Create bank accounts for users in different regions.

```ruby
bank_accounts = ZaiPayment::Resources::BankAccount.new

# Helper method to create region-specific bank account
def create_bank_account_for_region(bank_accounts, user_id, region, account_details)
  case region
  when :australia
    bank_accounts.create_au(
      user_id: user_id,
      **account_details
    )
  when :uk
    bank_accounts.create_uk(
      user_id: user_id,
      **account_details
    )
  else
    raise "Unsupported region: #{region}"
  end
end

# Australian user
aus_response = create_bank_account_for_region(
  bank_accounts,
  'user_aus_123',
  :australia,
  {
    bank_name: 'Bank of Australia',
    account_name: 'AU User',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'checking',
    holder_type: 'personal',
    country: 'AUS',
    payout_currency: 'AUD'
  }
)

puts "Australian account: #{aus_response.data['id']}" if aus_response.success?

# UK user
uk_response = create_bank_account_for_region(
  bank_accounts,
  'user_uk_456',
  :uk,
  {
    bank_name: 'UK Bank',
    account_name: 'UK User',
    routing_number: '111123',
    account_number: '111234',
    account_type: 'checking',
    holder_type: 'personal',
    country: 'GBR',
    iban: 'GB25QHWM02498765432109',
    swift_code: 'BUKBGB22',
    payout_currency: 'GBP'
  }
)

puts "UK account: #{uk_response.data['id']}" if uk_response.success?
```

## Important Notes

1. **Required Fields for Australia**:
   - `user_id`, `bank_name`, `account_name`, `routing_number` (BSB), `account_number`, `account_type`, `holder_type`, `country`

2. **Required Fields for UK** (includes all AU fields plus):
   - `iban` - International Bank Account Number
   - `swift_code` - SWIFT/BIC code

3. **Account Types**:
   - `checking` - Current/checking account
   - `savings` - Savings account

4. **Holder Types**:
   - `personal` - Personal/individual account
   - `business` - Business/company account

5. **Country Codes**:
   - Use ISO 3166-1 alpha-3 codes (3 letters)
   - Australia: `AUS`
   - United Kingdom: `GBR`

6. **Currency Codes**:
   - Use ISO 4217 alpha-3 codes
   - Australian Dollar: `AUD`
   - British Pound: `GBP`

7. **Bank Account Usage**:
   - Store the returned `:id` for future use in disbursements
   - Use `set_disbursement_account` to set the default payout account
   - The `:id` is also referred to as a `:token` when invoking bank accounts

