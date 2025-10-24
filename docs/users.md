# User Management

The User resource provides methods for managing Zai users (both payin and payout users).

## Overview

Zai supports two types of user onboarding:
- **Payin User (Buyer)**: A user who makes payments
- **Payout User (Seller/Merchant)**: A user who receives payments

Both user types use the same endpoints but have different required information based on their role and verification requirements.

## References

- [Onboarding a Payin User](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- [Onboarding a Payout User](https://developer.hellozai.com/docs/onboarding-a-pay-out-user)

## Usage

### Initialize the User Resource

```ruby
# Using the singleton instance
users = ZaiPayment.users

# Or create a new instance
users = ZaiPayment::Resources::User.new
```

## Methods

### List Users

Retrieve a list of all users with pagination support.

```ruby
# List users with default pagination (limit: 10, offset: 0)
response = ZaiPayment.users.list

# List users with custom pagination
response = ZaiPayment.users.list(limit: 20, offset: 10)

# Access the data
response.data # => Array of user objects
response.meta # => Pagination metadata
```

### Show User

Get details of a specific user by ID.

```ruby
response = ZaiPayment.users.show('user_id')

# Access user details
user = response.data
puts user['email']
puts user['first_name']
puts user['last_name']
```

### Create Payin User (Buyer)

Create a new payin user who will make payments on your platform.

#### Required Fields for Payin Users

- `user_type` - User type (must be 'payin')
- `email` - User's email address
- `first_name` - User's first name
- `last_name` - User's last name
- `country` - Country code (ISO 3166-1 alpha-3, e.g., USA, AUS, GBR)
- `device_id` - Required when an item is created and card is charged
- `ip_address` - Required when an item is created and card is charged

#### Recommended Fields

- `address_line1` - Street address
- `city` - City
- `state` - State/Province
- `zip` - Postal/ZIP code
- `mobile` - Mobile phone number
- `dob` - Date of birth (YYYYMMDD format)

#### Example

```ruby
response = ZaiPayment.users.create(
  user_type: 'payin',
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA',
  mobile: '+1234567890',
  address_line1: '123 Main St',
  city: 'New York',
  state: 'NY',
  zip: '10001',
  device_id: 'device_12345',
  ip_address: '192.168.1.1'
)

user = response.data
puts user['id'] # => "user_payin_123"
```

### Create Payout User (Seller/Merchant)

Create a new payout user who will receive payments. Payout users must undergo verification and provide more detailed information.

#### Required Fields for Payout Users (Individuals)

- `user_type` - User type (must be 'payout')
- `email` - User's email address
- `first_name` - User's first name
- `last_name` - User's last name
- `address_line1` - Street address (Required for payout)
- `city` - City (Required for payout)
- `state` - State/Province (Required for payout)
- `zip` - Postal/ZIP code (Required for payout)
- `country` - Country code (ISO 3166-1 alpha-3)
- `dob` - Date of birth (YYYYMMDD format, Required for payout)

#### Example

```ruby
response = ZaiPayment.users.create(
  user_type: 'payout',
  email: 'seller@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS',
  dob: '19900101',
  address_line1: '456 Market St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000',
  mobile: '+61412345678',
  government_number: 'TFN123456789'
)

user = response.data
puts user['id'] # => "user_payout_456"
puts user['verification_state'] # => "pending" or "approved"
```

### Update User

Update an existing user's information.

```ruby
response = ZaiPayment.users.update(
  'user_id',
  mobile: '+9876543210',
  address_line1: '789 New St',
  city: 'Los Angeles',
  state: 'CA',
  zip: '90001'
)

updated_user = response.data
```

### Show User Wallet Account

Show the user's wallet account using a given user ID.

```ruby
response = ZaiPayment.users.wallet_account('user_id')

wallet = response.data
puts wallet['id']
puts wallet['balance']
puts wallet['currency']
```

### List User Items

Retrieve an ordered and paginated list of existing items the user is associated with.

```ruby
# List items with default pagination (limit: 10, offset: 0)
response = ZaiPayment.users.items('user_id')

# List items with custom pagination
response = ZaiPayment.users.items('user_id', limit: 50, offset: 10)

# Access the items
response.data.each do |item|
  puts "Item ID: #{item['id']}"
  puts "Name: #{item['name']}"
  puts "Description: #{item['description']}"
  puts "Amount: #{item['amount']} #{item['currency']}"
  puts "State: #{item['state']}"
  puts "Status: #{item['status']}"
  puts "Payment Type: #{item['payment_type_id']}"
  
  # Buyer information
  puts "Buyer: #{item['buyer_name']} (#{item['buyer_country']})"
  puts "Buyer Email: #{item['buyer_email']}"
  
  # Seller information
  puts "Seller: #{item['seller_name']} (#{item['seller_country']})"
  puts "Seller Email: #{item['seller_email']}"
  
  # Access related resource links
  puts "Transactions URL: #{item['links']['transactions']}"
  puts "Fees URL: #{item['links']['fees']}"
end

# Access pagination metadata
puts "Total items: #{response.meta['total']}"
puts "Limit: #{response.meta['limit']}"
puts "Offset: #{response.meta['offset']}"
```

**Response Structure:**

```ruby
{
  "items" => [
    {
      "id" => "7139651-1-2046",
      "name" => "Item 7139651-1-2046",
      "description" => "Test Item 7139651-1-2046",
      "created_at" => "2020-05-05T12:26:50.782Z",
      "updated_at" => "2020-05-05T12:31:03.654Z",
      "state" => "payment_deposited",
      "payment_type_id" => 2,
      "status" => 22200,
      "amount" => 109,
      "deposit_reference" => "100014012501482",
      "buyer_name" => "Buyer Last Name",
      "buyer_country" => "AUS",
      "buyer_email" => "assemblybuyer71391895@assemblypayments.com",
      "seller_name" => "Assembly seller71391950",
      "seller_country" => "AUS",
      "seller_email" => "neol_seller71391950@assemblypayments.com",
      "tds_check_state" => "NA",
      "currency" => "AUD",
      "links" => {
        "self" => "/items/7139651-1-2046",
        "buyers" => "/items/7139651-1-2046/buyers",
        "sellers" => "/items/7139651-1-2046/sellers",
        "status" => "/items/7139651-1-2046/status",
        "fees" => "/items/7139651-1-2046/fees",
        "transactions" => "/items/7139651-1-2046/transactions",
        "batch_transactions" => "/items/7139651-1-2046/batch_transactions",
        "wire_details" => "/items/7139651-1-2046/wire_details",
        "bpay_details" => "/items/7139651-1-2046/bpay_details"
      }
    }
  ],
  "meta" => {
    "limit" => 10,
    "offset" => 0,
    "total" => 1
  }
}
```

### Set User Disbursement Account

Set the user's disbursement account using a given user ID and bank account ID.

```ruby
response = ZaiPayment.users.set_disbursement_account('user_id', 'bank_account_id')

puts "Disbursement account set: #{response.data['disbursement_account_id']}"
```

### Show User Bank Account

Show the user's active bank account using a given user ID.

```ruby
response = ZaiPayment.users.bank_account('user_id')

# Access bank account details
account = response.data
puts "Account ID: #{account['id']}"
puts "Active: #{account['active']}"
puts "Verification Status: #{account['verification_status']}"
puts "Currency: #{account['currency']}"

# Access nested bank details
bank = account['bank']
puts "Bank Name: #{bank['bank_name']}"
puts "Country: #{bank['country']}"
puts "Account Name: #{bank['account_name']}"
puts "Routing Number: #{bank['routing_number']}"
puts "Account Number: #{bank['account_number']}"
puts "Holder Type: #{bank['holder_type']}"
puts "Account Type: #{bank['account_type']}"

# Access related resource links
puts "Self URL: #{account['links']['self']}"
puts "Users URL: #{account['links']['users']}"
```

**Response Structure:**

```ruby
{
  "bank_accounts" => {
    "id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
    "created_at" => "2016-04-12T09:20:38.540Z",
    "updated_at" => "2016-04-12T09:20:38.540Z",
    "active" => true,
    "verification_status" => "not_verified",
    "currency" => "AUD",
    "bank" => {
      "bank_name" => "Bank of Australia",
      "country" => "AUS",
      "account_name" => "Samuel Seller",
      "routing_number" => "XXXXX3",
      "account_number" => "XXX234",
      "holder_type" => "personal",
      "account_type" => "checking",
      "direct_debit_authority_status" => nil
    },
    "links" => {
      "self" => "/users/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/bank_accounts",
      "users" => "/bank_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/users",
      "direct_debit_authorities" => "/bank_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/direct_debit_authorities"
    }
  }
}
```

### Verify User (Prelive Only)

Sets a user's verification state to approved on pre-live environment. This endpoint only works in the pre-live environment. The user verification workflow holds for all users in production.

```ruby
response = ZaiPayment.users.verify('user_id')

puts "User verified: #{response.data['verification_state']}"
```

**Note:** This is only available in the pre-live/test environment and will not work in production.

### Show User Card Account

Show the user's active card account using a given user ID.

```ruby
response = ZaiPayment.users.card_account('user_id')

# Access card account details
account = response.data
puts "Account ID: #{account['id']}"
puts "Active: #{account['active']}"
puts "Verification Status: #{account['verification_status']}"
puts "CVV Verified: #{account['cvv_verified']}"
puts "Currency: #{account['currency']}"

# Access nested card details
card = account['card']
puts "Card Type: #{card['type']}"
puts "Cardholder Name: #{card['full_name']}"
puts "Card Number: #{card['number']}"
puts "Expiry: #{card['expiry_month']}/#{card['expiry_year']}"

# Access related resource links
puts "Self URL: #{account['links']['self']}"
puts "Users URL: #{account['links']['users']}"
```

**Response Structure:**

```ruby
{
  "card_accounts" => {
    "active" => true,
    "created_at" => "2020-05-06T01:38:29.022Z",
    "updated_at" => "2020-05-06T01:38:29.022Z",
    "id" => "35977230-7168-0138-0a1d-0a58a9feac07",
    "verification_status" => "not_verified",
    "cvv_verified" => true,
    "currency" => "AUD",
    "card" => {
      "type" => "visa",
      "full_name" => "Neol Test",
      "number" => "XXXX-XXXX-XXXX-1111",
      "expiry_month" => "7",
      "expiry_year" => "2021"
    },
    "links" => {
      "self" => "/users/buyer-71439598/card_accounts",
      "users" => "/card_accounts/35977230-7168-0138-0a1d-0a58a9feac07/users"
    }
  }
}
```

### List User's BPay Accounts

List the BPay accounts the user is associated with using a given user ID.

```ruby
response = ZaiPayment.users.bpay_accounts('user_id')

# Access the BPay accounts
response.data.each do |account|
  puts "BPay Account ID: #{account['id']}"
  puts "Active: #{account['active']}"
  puts "Verification Status: #{account['verification_status']}"
  
  # Access BPay details
  details = account['bpay_details']
  puts "Biller Name: #{details['biller_name']}"
  puts "Biller Code: #{details['biller_code']}"
  puts "Account Name: #{details['account_name']}"
  puts "CRN: #{details['crn']}"
  puts "Currency: #{account['currency']}"
end

# Access pagination metadata
puts "Total accounts: #{response.meta['total']}"
```

**Response Structure:**

```ruby
{
  "bpay_accounts" => [
    {
      "id" => "b0980390-ac5b-0138-8b2e-0a58a9feac03",
      "active" => true,
      "created_at" => "2020-07-20 02:07:33.583000+00:00",
      "updated_at" => "2020-07-20 02:07:33.583000+00:00",
      "bpay_details" => {
        "biller_name" => "APIBCD AV4",
        "account_name" => "Test Biller",
        "biller_code" => "93815",
        "crn" => "613295205"
      },
      "currency" => "AUD",
      "verification_status" => "verified",
      "links" => {
        "self" => "/bpay_accounts/b0980390-ac5b-0138-8b2e-0a58a9feac03",
        "users" => "/bpay_accounts/b0980390-ac5b-0138-8b2e-0a58a9feac03/users"
      }
    }
  ],
  "meta" => {
    "limit" => 10,
    "offset" => 0,
    "total" => 1
  }
}
```

### Create Business User with Company

Create a payout user representing a business entity with full company details. This is useful for merchants, marketplace sellers, or any business that needs to receive payments.

#### Required Company Fields

When the `company` parameter is provided, the following fields are required:
- `name` - Company name
- `legal_name` - Legal business name
- `tax_number` - Tax/ABN/TFN number
- `business_email` - Business email address
- `country` - Country code (ISO 3166-1 alpha-3)

#### Example

```ruby
response = ZaiPayment.users.create(
  # Personal details (authorized signer)
  user_type: 'payout',
  email: 'john.director@example.com',
  first_name: 'John',
  last_name: 'Smith',
  country: 'AUS',
  mobile: '+61412345678',
  
  # Job title (required for AMEX merchants)
  authorized_signer_title: 'Director',
  
  # Company details
  company: {
    name: 'Smith Trading Co',
    legal_name: 'Smith Trading Company Pty Ltd',
    tax_number: '53004085616',  # ABN for Australian companies
    business_email: 'accounts@smithtrading.com',
    country: 'AUS',
    charge_tax: true,  # GST registered
    
    # Optional company fields
    address_line1: '123 Business Street',
    address_line2: 'Suite 5',
    city: 'Melbourne',
    state: 'VIC',
    zip: '3000',
    phone: '+61398765432'
  }
)

user = response.data
puts "Business user created: #{user['id']}"
puts "Company: #{user['company']['name']}"
```

## Field Reference

### All User Fields

| Field | Type | Description | Payin Required | Payout Required |
|-------|------|-------------|----------------|-----------------|
| `user_type` | String | User type ('payin' or 'payout') | ✓ | ✓ |
| `email` | String | User's email address | ✓ | ✓ |
| `first_name` | String | User's first name | ✓ | ✓ |
| `last_name` | String | User's last name | ✓ | ✓ |
| `country` | String | ISO 3166-1 alpha-3 country code | ✓ | ✓ |
| `address_line1` | String | Street address | Recommended | ✓ |
| `address_line2` | String | Additional address info | Optional | Optional |
| `city` | String | City | Recommended | ✓ |
| `state` | String | State/Province | Recommended | ✓ |
| `zip` | String | Postal/ZIP code | Recommended | ✓ |
| `mobile` | String | Mobile phone number (international format) | Recommended | Recommended |
| `phone` | String | Phone number | Optional | Optional |
| `dob` | String | Date of birth (DD/MM/YYYY) | Recommended | ✓ |
| `government_number` | String | Tax/Government ID (SSN, TFN, etc.) | Optional | Recommended |
| `drivers_license_number` | String | Driving license number | Optional | Optional |
| `drivers_license_state` | String | State section of driving license | Optional | Optional |
| `logo_url` | String | URL link to logo | Optional | Optional |
| `color_1` | String | Color code number 1 | Optional | Optional |
| `color_2` | String | Color code number 2 | Optional | Optional |
| `custom_descriptor` | String | Custom text for bank statements | Optional | Optional |
| `authorized_signer_title` | String | Job title (e.g., Director) - Required for AMEX | Optional | AMEX Required |
| `company` | Object | Company details (see below) | Optional | Optional |
| `device_id` | String | Device ID for fraud prevention | When charging* | N/A |
| `ip_address` | String | IP address for fraud prevention | When charging* | N/A |

\* Required when an item is created and a card is charged

### Company Object Fields

When creating a business user, you can provide a `company` object with the following fields:

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `name` | String | Company name | ✓ |
| `legal_name` | String | Legal business name | ✓ |
| `tax_number` | String | ABN/TFN/Tax number | ✓ |
| `business_email` | String | Business email address | ✓ |
| `country` | String | Country code (ISO 3166-1 alpha-3) | ✓ |
| `charge_tax` | Boolean | Charge GST/tax? (true/false) | Optional |
| `address_line1` | String | Business address line 1 | Optional |
| `address_line2` | String | Business address line 2 | Optional |
| `city` | String | Business city | Optional |
| `state` | String | Business state | Optional |
| `zip` | String | Business postal code | Optional |
| `phone` | String | Business phone number | Optional |

## Error Handling

The User resource will raise validation errors for:

- Missing required fields
- Invalid email format
- Invalid country code (must be ISO 3166-1 alpha-3)
- Invalid date of birth format (must be YYYYMMDD)
- Invalid user type (must be 'payin' or 'payout')

```ruby
begin
  response = ZaiPayment.users.create(
    email: 'invalid-email',
    first_name: 'John',
    last_name: 'Doe',
    country: 'USA'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### For Payin Users

1. **Collect information progressively**: You can create a payin user with minimal information and update it later as needed.
2. **Capture device information**: Use Hosted Forms and Hosted Fields to capture device ID and IP address when processing payments.
3. **Store device_id and ip_address**: These are required when creating items and charging cards for fraud prevention.

### For Payout Users

1. **Collect complete information upfront**: Payout users require more detailed information for verification and underwriting.
2. **Verify date of birth format**: Ensure DOB is in YYYYMMDD format (e.g., 19900101).
3. **Provide accurate address**: Complete address information is required for payout users to pass verification.
4. **Handle verification states**: Payout users go through verification (`pending`, `pending_check`, `approved`, etc.).

## Response Structure

### Successful Response

```ruby
response.success? # => true
response.status   # => 200 or 201
response.data     # => User object hash
response.meta     # => Pagination metadata (for list)
```

### User Object

```ruby
{
  "id" => "user_123",
  "email" => "user@example.com",
  "first_name" => "John",
  "last_name" => "Doe",
  "country" => "USA",
  "address_line1" => "123 Main St",
  "city" => "New York",
  "state" => "NY",
  "zip" => "10001",
  "mobile" => "+1234567890",
  "dob" => "19900101",
  "verification_state" => "approved",
  "created_at" => "2025-01-01T00:00:00Z",
  "updated_at" => "2025-01-01T00:00:00Z"
}
```

## Complete Examples

### Example 1: Create and Update a Payin User

```ruby
# Step 1: Create a payin user with minimal info
response = ZaiPayment.users.create(
  user_type: 'payin',
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)

user_id = response.data['id']

# Step 2: Update with additional info later
ZaiPayment.users.update(
  user_id,
  address_line1: '123 Main St',
  city: 'New York',
  state: 'NY',
  zip: '10001',
  mobile: '+1234567890'
)
```

### Example 2: Create a Payout User with Complete Information

```ruby
response = ZaiPayment.users.create(
  # Required fields
  user_type: 'payout',
  email: 'seller@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS',
  dob: '19900101',
  address_line1: '456 Market St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000',
  
  # Additional recommended fields
  mobile: '+61412345678',
  government_number: 'TFN123456789'
)

user = response.data
puts "Created payout user: #{user['id']}"
puts "Verification state: #{user['verification_state']}"
```

### Example 3: List and Filter Users

```ruby
# Get first page of users
response = ZaiPayment.users.list(limit: 10, offset: 0)

response.data.each do |user|
  puts "#{user['email']} - #{user['first_name']} #{user['last_name']}"
end

# Get next page
next_response = ZaiPayment.users.list(limit: 10, offset: 10)
```

## Testing

The User resource includes comprehensive test coverage. Run the tests with:

```bash
bundle exec rspec spec/zai_payment/resources/user_spec.rb
```

## See Also

- [Webhook Documentation](webhooks.md)
- [Authentication Documentation](authentication.md)
- [Architecture Documentation](architecture.md)

