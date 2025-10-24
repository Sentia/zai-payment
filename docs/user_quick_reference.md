# User Management Quick Reference

Quick reference guide for the ZaiPayment User Management API.

## Quick Start

```ruby
require 'zai_payment'

# Configure
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end
```

## CRUD Operations

### List Users
```ruby
response = ZaiPayment.users.list(limit: 10, offset: 0)
users = response.data
```

### Show User
```ruby
response = ZaiPayment.users.show('user_id')
user = response.data
```

### Create Payin User
```ruby
response = ZaiPayment.users.create(
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)
```

### Create Payout User
```ruby
response = ZaiPayment.users.create(
  email: 'seller@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS',
  dob: '19900101',
  address_line1: '123 Main St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000'
)
```

### Update User
```ruby
response = ZaiPayment.users.update(
  'user_id',
  mobile: '+1234567890',
  city: 'New York'
)
```

## Required Fields

### Payin User (Buyer)
| Field | Type | Required |
|-------|------|----------|
| email | String | ✓ |
| first_name | String | ✓ |
| last_name | String | ✓ |
| country | String (ISO 3166-1 alpha-3) | ✓ |
| device_id | String | When charging* |
| ip_address | String | When charging* |

### Payout User (Seller/Merchant)
| Field | Type | Required |
|-------|------|----------|
| email | String | ✓ |
| first_name | String | ✓ |
| last_name | String | ✓ |
| country | String (ISO 3166-1 alpha-3) | ✓ |
| dob | String (DD/MM/YYYY) | ✓ |
| address_line1 | String | ✓ |
| city | String | ✓ |
| state | String | ✓ |
| zip | String | ✓ |

\* Required when an item is created and a card is charged

## Validation Formats

### Email
```ruby
email: 'user@example.com'
```

### Country Code (ISO 3166-1 alpha-3)
```ruby
country: 'USA'  # United States
country: 'AUS'  # Australia
country: 'GBR'  # United Kingdom
country: 'CAN'  # Canada
```

### Date of Birth (DD/MM/YYYY)
```ruby
dob: '19900101'  # January 1, 1990
```

## Error Handling

```ruby
begin
  response = ZaiPayment.users.create(...)
rescue ZaiPayment::Errors::ValidationError => e
  # Handle validation errors (400, 422)
rescue ZaiPayment::Errors::UnauthorizedError => e
  # Handle auth errors (401)
rescue ZaiPayment::Errors::NotFoundError => e
  # Handle not found (404)
rescue ZaiPayment::Errors::ApiError => e
  # Handle general API errors
end
```

## Common Patterns

### Progressive Profile
```ruby
# 1. Quick signup
response = ZaiPayment.users.create(
  email: 'user@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)
user_id = response.data['id']

# 2. Add details later
ZaiPayment.users.update(
  user_id,
  address_line1: '123 Main St',
  city: 'New York',
  state: 'NY',
  zip: '10001'
)
```

### Batch Creation
```ruby
users_data.each do |data|
  begin
    ZaiPayment.users.create(**data)
  rescue ZaiPayment::Errors::ApiError => e
    # Log error and continue
  end
end
```

## Response Structure

### Success Response
```ruby
response.success?  # => true
response.status    # => 200 or 201
response.data      # => User hash
response.meta      # => Metadata (for list)
```

### User Object
```ruby
{
  "id" => "user_123",
  "email" => "user@example.com",
  "first_name" => "John",
  "last_name" => "Doe",
  "country" => "USA",
  "created_at" => "2025-01-01T00:00:00Z",
  ...
}
```

## Country Codes Reference

Common ISO 3166-1 alpha-3 country codes:

| Country | Code |
|---------|------|
| United States | USA |
| Australia | AUS |
| United Kingdom | GBR |
| Canada | CAN |
| New Zealand | NZL |
| Germany | DEU |
| France | FRA |
| Japan | JPN |
| Singapore | SGP |

[Full list](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3)

## Testing

### Run Tests
```bash
bundle exec rspec spec/zai_payment/resources/user_spec.rb
```

### Run Demo
```bash
ruby examples/user_demo.rb
```

## Documentation Links

- [Full User Guide](users.md)
- [Usage Examples](../examples/users.md)
- [Zai: Payin User](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- [Zai: Payout User](https://developer.hellozai.com/docs/onboarding-a-pay-out-user)

## Support

For issues or questions:
1. Check the [User Management Guide](users.md)
2. Review [Examples](../examples/users.md)
3. Visit [Zai Developer Portal](https://developer.hellozai.com/)

