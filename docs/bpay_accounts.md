# BPay Account Management

The BpayAccount resource provides methods for managing Zai BPay accounts for Australian bill payments.

## Overview

BPay accounts are used as disbursement destinations for Australian bill payments. BPay is a popular Australian electronic bill payment system that allows payments to be made through the customer's internet or telephone banking facility.

Once created, store the returned `:id` and use it for disbursement operations. The `:id` is also referred to as a `:token` when invoking BPay Accounts.

## References

- [Create BPay Account API](https://developer.hellozai.com/reference/createbpayaccount)
- [BPay Overview](https://developer.hellozai.com/docs/bpay)

## Usage

### Initialize the BpayAccount Resource

```ruby
# Using a new instance
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Or use with custom client
client = ZaiPayment::Client.new
bpay_accounts = ZaiPayment::Resources::BpayAccount.new(client: client)
```

## Methods

### Show BPay Account

Get details of a specific BPay account by ID.

#### Parameters

- `bpay_account_id` (required) - The BPay account ID

#### Example

```ruby
# Get BPay account details
response = bpay_accounts.show('bpay_account_id')

# Access BPay account details
bpay_account = response.data
puts bpay_account['id']
puts bpay_account['active']
puts bpay_account['verification_status']
puts bpay_account['currency']

# Access BPay details
bpay_details = bpay_account['bpay_details']
puts bpay_details['account_name']
puts bpay_details['biller_code']
puts bpay_details['biller_name']
puts bpay_details['crn']
```

#### Response

```ruby
{
  "bpay_accounts" => {
    "id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "active" => true,
    "created_at" => "2020-04-03T07:59:00.379Z",
    "updated_at" => "2020-04-03T07:59:00.379Z",
    "verification_status" => "not_verified",
    "currency" => "AUD",
    "bpay_details" => {
      "account_name" => "My Water Bill Company",
      "biller_code" => 123456,
      "biller_name" => "ABC Water",
      "crn" => 987654321
    },
    "links" => {
      "self" => "/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "users" => "/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users"
    }
  }
}
```

**Use Cases:**
- Retrieve BPay account details before disbursement
- Verify account status and verification
- Check biller information
- Validate account is active

### Show BPay Account User

Get the User the BPay Account is associated with using a given bpay_account_id.

#### Parameters

- `bpay_account_id` (required) - The BPay account ID

#### Example

```ruby
# Get user associated with BPay account
response = bpay_accounts.show_user('bpay_account_id')

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
      "self" => "/bpay_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/users",
      "items" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/items",
      "card_accounts" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/card_accounts",
      "bpay_accounts" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/bpay_accounts",
      "wallet_accounts" => "/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/wallet_accounts"
    }
  }
}
```

**Use Cases:**
- Retrieve user information for a BPay account
- Verify user identity before disbursement
- Check user verification status
- Get user contact details for notifications

### Redact BPay Account

Redact a BPay account using the given bpay_account_id. Redacted BPay accounts can no longer be used as a disbursement destination.

**Note**: This is marked as a "Future Feature" in the Zai API documentation but is implemented for forward compatibility.

#### Parameters

- `bpay_account_id` (required) - The BPay account ID

#### Example

```ruby
response = bpay_accounts.redact('bpay_account_id')

if response.success?
  puts "BPay account successfully redacted"
else
  puts "Failed to redact BPay account"
end
```

#### Response

```ruby
{
  "bpay_account" => "Successfully redacted"
}
```

**Important Notes:**
- Once redacted, the BPay account cannot be used for disbursements
- This action cannot be undone
- Use with caution

### Create BPay Account

Create a BPay Account to be used as a Disbursement destination.

#### Required Fields

- `user_id` - User ID (UUID format)
- `account_name` - Name assigned by the platform/marketplace to identify the account (similar to a nickname). Defaults to "My Water Bill Company"
- `biller_code` - The Biller Code for the biller that will receive the payment. Must be a numeric value with 3 to 10 digits.
- `bpay_crn` - Customer reference number (crn) to be used for this BPay account. The CRN must contain between 2 and 20 digits. Defaults to "987654321"

#### Example

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

response = bpay_accounts.create(
  user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  account_name: 'My Water Bill Company',
  biller_code: 123456,
  bpay_crn: '987654321'
)

if response.success?
  bpay_account = response.data
  puts "BPay Account ID: #{bpay_account['id']}"
  puts "Active: #{bpay_account['active']}"
  puts "Verification Status: #{bpay_account['verification_status']}"
  puts "Currency: #{bpay_account['currency']}"
  
  # Access BPay details
  bpay_details = bpay_account['bpay_details']
  puts "Account Name: #{bpay_details['account_name']}"
  puts "Biller Code: #{bpay_details['biller_code']}"
  puts "Biller Name: #{bpay_details['biller_name']}"
  puts "CRN: #{bpay_details['crn']}"
  
  # Access links
  links = bpay_account['links']
  puts "Self Link: #{links['self']}"
  puts "Users Link: #{links['users']}"
end
```

## Response Structure

The methods return a `ZaiPayment::Response` object with the following structure:

```ruby
{
  "bpay_accounts" => {
    "id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "created_at" => "2020-04-03T07:59:00.379Z",
    "updated_at" => "2020-04-03T07:59:00.379Z",
    "active" => true,
    "verification_status" => "not_verified",
    "currency" => "AUD",
    "bpay_details" => {
      "account_name" => "My Water Bill Company",
      "biller_code" => 123456,
      "biller_name" => "ABC Water",
      "crn" => 987654321
    },
    "links" => {
      "self" => "/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "users" => "/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users"
    }
  }
}
```

## Validation Rules

### Biller Code

- Must be a numeric value
- Must contain between 3 and 10 digits
- Examples: `123`, `123456`, `1234567890`

### BPay CRN (Customer Reference Number)

- Must be numeric
- Must contain between 2 and 20 digits
- Examples: `12`, `987654321`, `12345678901234567890`

### Account Name

- Required field
- Used to identify the account (similar to a nickname)
- Should be descriptive (e.g., "Water Bill", "Electricity Account")

### User ID

- Required field
- Must be a valid UUID
- Must reference an existing user in the system

## Error Handling

The BpayAccount resource raises the following errors:

### NotFoundError

Raised when the BPay account does not exist:

```ruby
begin
  bpay_accounts.show('invalid_id')
rescue ZaiPayment::Errors::NotFoundError => e
  puts "BPay account not found: #{e.message}"
end
```

### ValidationError

Raised when required fields are missing or invalid:

```ruby
begin
  bpay_accounts.create(
    user_id: 'user_123',
    account_name: 'Test Account'
    # Missing required fields
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # => "Missing required fields: biller_code, bpay_crn"
end
```

### Invalid Biller Code

```ruby
begin
  bpay_accounts.create(
    user_id: 'user_123',
    account_name: 'Test Account',
    biller_code: 12,  # Only 2 digits (requires 3-10)
    bpay_crn: '987654321'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "biller_code must be a numeric value with 3 to 10 digits"
end
```

### Invalid BPay CRN

```ruby
begin
  bpay_accounts.create(
    user_id: 'user_123',
    account_name: 'Test Account',
    biller_code: 123456,
    bpay_crn: '1'  # Only 1 digit (requires 2-20)
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "bpay_crn must contain between 2 and 20 digits"
end
```

### Blank BPay Account ID

Raised when trying to show or redact a BPay account with blank/nil ID:

```ruby
begin
  bpay_accounts.show('')
  # or
  bpay_accounts.redact(nil)
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid ID: #{e.message}"
  # => "bpay_account_id is required and cannot be blank"
end
```

## Use Cases

### Use Case 1: Disbursement Account for Bill Payments

After creating a payout user, create a BPay account for receiving bill payments:

```ruby
# Step 1: Create payout user
users = ZaiPayment::Resources::User.new
user_response = users.create(
  user_type: 'payout',
  email: 'biller@example.com',
  first_name: 'Water',
  last_name: 'Company',
  country: 'AUS',
  dob: '01/01/1990',
  address_line1: '123 Main St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000'
)

user_id = user_response.data['id']

# Step 2: Create BPay account
bpay_accounts = ZaiPayment::Resources::BpayAccount.new
bpay_response = bpay_accounts.create(
  user_id: user_id,
  account_name: 'Water Bill Payment',
  biller_code: 123456,
  bpay_crn: '987654321'
)

account_id = bpay_response.data['id']

# Step 3: Set as disbursement account
users.set_disbursement_account(user_id, account_id)
```

### Use Case 2: Get User Details for BPay Account

Retrieve user information associated with a BPay account:

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Step 1: Get user details
user_response = bpay_accounts.show_user('bpay_account_id')

if user_response.success?
  user = user_response.data
  
  # Step 2: Verify user is eligible for disbursement
  if user['verification_state'] == 'verified' && !user['held_state']
    puts "User eligible for disbursement"
    puts "Name: #{user['full_name']}"
    puts "Email: #{user['email']}"
    
    # Proceed with disbursement
  else
    puts "User not eligible"
    puts "Verification: #{user['verification_state']}"
    puts "Held: #{user['held_state']}"
  end
end
```

### Use Case 3: Deactivate Old BPay Account

Redact an old BPay account that is no longer needed:

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Step 1: Verify the account before redacting
response = bpay_accounts.show('old_bpay_account_id')

if response.success?
  bpay_account = response.data
  puts "Redacting: #{bpay_account['bpay_details']['account_name']}"
  
  # Step 2: Redact the account
  redact_response = bpay_accounts.redact('old_bpay_account_id')
  
  if redact_response.success?
    puts "BPay account successfully redacted"
  end
end
```

### Use Case 4: Multiple Utility BPay Accounts

Create multiple BPay accounts for different utility bills:

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Water bill
water_response = bpay_accounts.create(
  user_id: 'user_123',
  account_name: 'Sydney Water Bill',
  biller_code: 12345,
  bpay_crn: '1122334455'
)

# Electricity bill
electricity_response = bpay_accounts.create(
  user_id: 'user_123',
  account_name: 'Energy Australia Bill',
  biller_code: 67890,
  bpay_crn: '9988776655'
)

# Gas bill
gas_response = bpay_accounts.create(
  user_id: 'user_123',
  account_name: 'AGL Gas Bill',
  biller_code: 54321,
  bpay_crn: '5566778899'
)
```

## Important Notes

1. **Australian Only**: BPay is an Australian payment system and typically uses AUD currency
2. **Disbursement Use**: BPay accounts are used as disbursement destinations, not funding sources
3. **Verification**: New BPay accounts typically have `verification_status: "not_verified"` until verified by Zai
4. **Biller Information**: The API returns `biller_name` which is retrieved based on the `biller_code`
5. **Token Usage**: The returned `id` can be used as a token for disbursement operations
6. **CRN Format**: The CRN (Customer Reference Number) format may vary by biller - check with the specific biller for their format requirements

## Common BPay Billers

BPay biller codes are assigned by BPAY. Some common categories include:

- **Utilities**: Water, electricity, gas
- **Telecommunications**: Phone, internet, mobile
- **Financial Services**: Credit cards, loans, insurance
- **Government**: Council rates, fines, taxes

**Note**: Always verify the biller code with the actual biller before creating a BPay account.

## Related Resources

- [User Management](users.md) - Creating and managing users
- [Disbursement Accounts](users.md#set-disbursement-account) - Setting default payout accounts

## Further Reading

- [BPay Overview](https://www.bpay.com.au/)
- [Payment Methods Guide](https://developer.hellozai.com/docs/payment-methods)
- [Verification Process](https://developer.hellozai.com/docs/verification)

