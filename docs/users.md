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
| `user_type` | String | 'payin' or 'payout' | Optional | Optional |

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
  government_number: 'TFN123456789',
  user_type: 'payout'
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

- [Webhook Documentation](WEBHOOKS.md)
- [Authentication Documentation](AUTHENTICATION.md)
- [Architecture Documentation](ARCHITECTURE.md)

