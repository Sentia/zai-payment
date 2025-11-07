# PayID Management

The PayId resource provides methods for registering and managing Zai PayIDs for virtual accounts.

## Overview

PayIDs are easy-to-remember identifiers (like email addresses) that can be used instead of BSB and account numbers for receiving payments in Australia's New Payments Platform (NPP). They provide a more user-friendly way for customers to make payments.

PayIDs are particularly useful for:
- Simplifying payment collection with memorable identifiers
- Enabling fast payments through the New Payments Platform
- Providing customers with an alternative to BSB and account numbers
- Enhancing user experience with familiar email-based identifiers

## Key Features

- **Email-based PayIDs**: Register email addresses as payment identifiers
- **Linked to Virtual Accounts**: Each PayID is associated with a virtual account
- **Status Tracking**: Monitor PayID status (pending_activation, active, etc.)
- **Secure Registration**: Validated registration process with proper error handling

## References

- [PayID API](https://developer.hellozai.com/reference/registerpayid)
- [Zai API Documentation](https://developer.hellozai.com/docs)

## Usage

### Initialize the PayId Resource

```ruby
# Using a new instance
pay_ids = ZaiPayment::Resources::PayId.new

# Or use with custom client
client = ZaiPayment::Client.new(base_endpoint: :va_base)
pay_ids = ZaiPayment::Resources::PayId.new(client: client)
```

## Methods

### Register PayID

Register a PayID for a given Virtual Account. This creates a PayID that customers can use to send payments to the virtual account.

#### Parameters

- `virtual_account_id` (required) - The virtual account ID
- `pay_id` (required) - The PayID being registered (max 256 characters)
- `type` (required) - The type of PayID (currently only 'EMAIL' is supported)
- `details` (required) - Hash containing additional details:
  - `pay_id_name` (optional) - Name to identify the entity (1-140 characters)
  - `owner_legal_name` (optional) - Full legal account name (1-140 characters)

#### Example

```ruby
# Register an EMAIL PayID
pay_ids = ZaiPayment::Resources::PayId.new

response = pay_ids.create(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  pay_id: 'jsmith@mydomain.com',
  type: 'EMAIL',
  details: {
    pay_id_name: 'J Smith',
    owner_legal_name: 'Mr John Smith'
  }
)

# Access PayID details
if response.success?
  pay_id = response.data
  
  puts "PayID: #{pay_id['pay_id']}"
  puts "Type: #{pay_id['type']}"
  puts "Status: #{pay_id['status']}"
  puts "PayID Name: #{pay_id['details']['pay_id_name']}"
  puts "Owner Legal Name: #{pay_id['details']['owner_legal_name']}"
end
```

#### Response

```ruby
{
  "pay_ids" => {
    "id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
    "pay_id" => "jsmith@mydomain.com",
    "type" => "EMAIL",
    "status" => "pending_activation",
    "created_at" => "2020-04-27T20:28:22.378Z",
    "updated_at" => "2020-04-27T20:28:22.378Z",
    "details" => {
      "pay_id_name" => "J Smith",
      "owner_legal_name" => "Mr John Smith"
    },
    "links" => {
      "self" => "/pay_ids/46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
      "virtual_accounts" => "/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc"
    }
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier for the PayID |
| `pay_id` | String | The registered PayID (email address) |
| `type` | String | Type of PayID (e.g., "EMAIL") |
| `status` | String | PayID status (pending_activation, active, etc.) |
| `created_at` | String | ISO 8601 timestamp of creation |
| `updated_at` | String | ISO 8601 timestamp of last update |
| `details` | Hash | Additional PayID details |
| `details.pay_id_name` | String | Name to identify the entity |
| `details.owner_legal_name` | String | Full legal account name |
| `links` | Hash | Related resource links |
| `links.self` | String | URL to the PayID resource |
| `links.virtual_accounts` | String | URL to the associated virtual account |

**Use Cases:**

- Register PayIDs for easy customer payments
- Enable NPP fast payments
- Provide user-friendly payment identifiers
- Link email addresses to virtual accounts for payment collection
- Set up payment collection for businesses and individuals

## Validation Rules

### virtual_account_id

- **Required**: Yes
- **Type**: String (UUID)
- **Description**: The ID of the virtual account that this PayID will be linked to. The virtual account must exist before registering a PayID.

### pay_id

- **Required**: Yes
- **Type**: String
- **Max Length**: 256 characters
- **Description**: The PayID being registered. For EMAIL type, this should be a valid email address.

### type

- **Required**: Yes
- **Type**: String (Enum)
- **Allowed Values**: EMAIL
- **Description**: The type of PayID being registered. Currently, only EMAIL type is supported.

### details

- **Required**: Yes
- **Type**: Hash
- **Description**: Additional details about the PayID registration.

#### details.pay_id_name

- **Required**: No
- **Type**: String
- **Length**: 1-140 characters (when provided)
- **Description**: A name that can be used to identify the entity registering the PayID. This helps customers confirm they're sending to the right recipient.

#### details.owner_legal_name

- **Required**: No
- **Type**: String
- **Length**: 1-140 characters (when provided)
- **Description**: The full legal account name. This is displayed to customers during payment confirmation.

## Error Handling

The PayId methods can raise the following errors:

### ZaiPayment::Errors::ValidationError

Raised when input parameters fail validation:

```ruby
begin
  response = pay_ids.create(
    '',  # Empty virtual_account_id
    pay_id: 'test@example.com',
    type: 'EMAIL',
    details: {}
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # Output: "virtual_account_id is required and cannot be blank"
end
```

**Common validation errors:**
- `virtual_account_id is required and cannot be blank`
- `pay_id is required and cannot be blank`
- `pay_id must be 256 characters or less`
- `type is required and cannot be blank`
- `type must be one of: EMAIL`
- `details is required and must be a hash`
- `pay_id_name must be between 1 and 140 characters`
- `owner_legal_name must be between 1 and 140 characters`

### ZaiPayment::Errors::NotFoundError

Raised when the virtual account doesn't exist:

```ruby
begin
  response = pay_ids.create(
    'invalid-virtual-account-id',
    pay_id: 'test@example.com',
    type: 'EMAIL',
    details: {}
  )
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Not found: #{e.message}"
end
```

### ZaiPayment::Errors::UnauthorizedError

Raised when authentication fails:

```ruby
begin
  response = pay_ids.create(
    virtual_account_id,
    pay_id: 'test@example.com',
    type: 'EMAIL',
    details: {}
  )
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication failed: #{e.message}"
  # Check your API credentials
end
```

### ZaiPayment::Errors::BadRequestError

Raised when the request is malformed or contains invalid data (e.g., PayID already registered):

```ruby
begin
  response = pay_ids.create(
    virtual_account_id,
    pay_id: 'test@example.com',
    type: 'EMAIL',
    details: {}
  )
rescue ZaiPayment::Errors::BadRequestError => e
  puts "Bad request: #{e.message}"
  # May indicate PayID is already registered
end
```

## Complete Example

Here's a complete workflow showing how to create a virtual account and register a PayID with proper error handling:

```ruby
require 'zai_payment'

# Configure ZaiPayment
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end

# Initialize resources
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
pay_ids = ZaiPayment::Resources::PayId.new
wallet_account_id = 'ae07556e-22ef-11eb-adc1-0242ac120002'

begin
  # Step 1: Create a Virtual Account
  puts "Creating virtual account..."
  
  va_response = virtual_accounts.create(
    wallet_account_id,
    account_name: 'Customer Payment Account',
    aka_names: ['Customer Account']
  )
  
  if va_response.success?
    virtual_account = va_response.data
    virtual_account_id = virtual_account['id']
    
    puts "✓ Virtual Account Created"
    puts "  ID: #{virtual_account_id}"
    puts "  BSB: #{virtual_account['routing_number']}"
    puts "  Account: #{virtual_account['account_number']}"
    puts "  Status: #{virtual_account['status']}"
    
    # Step 2: Register PayID
    puts "\nRegistering PayID..."
    
    payid_response = pay_ids.create(
      virtual_account_id,
      pay_id: 'customer@mybusiness.com',
      type: 'EMAIL',
      details: {
        pay_id_name: 'My Business',
        owner_legal_name: 'My Business Pty Ltd'
      }
    )
    
    if payid_response.success?
      pay_id = payid_response.data
      
      puts "✓ PayID Registered Successfully!"
      puts "─" * 60
      puts "PayID Details:"
      puts "  ID: #{pay_id['id']}"
      puts "  PayID: #{pay_id['pay_id']}"
      puts "  Type: #{pay_id['type']}"
      puts "  Status: #{pay_id['status']}"
      puts ""
      puts "Payment Information:"
      puts "  PayID Name: #{pay_id['details']['pay_id_name']}"
      puts "  Owner Legal Name: #{pay_id['details']['owner_legal_name']}"
      puts ""
      puts "Customers can now send payments using:"
      puts "  PayID: #{pay_id['pay_id']}"
      puts "  OR"
      puts "  BSB: #{virtual_account['routing_number']}"
      puts "  Account: #{virtual_account['account_number']}"
      puts "─" * 60
      
      # Store the details in your database for future reference
      # YourDatabase.store_pay_id(pay_id)
    else
      puts "Failed to register PayID"
    end
  else
    puts "Failed to create virtual account"
  end

rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
  puts "Please check your input parameters"
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource Not Found: #{e.message}"
  puts "Please verify the wallet account or virtual account exists"
  
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication Failed: #{e.message}"
  puts "Please check your API credentials"
  
rescue ZaiPayment::Errors::BadRequestError => e
  puts "Bad Request: #{e.message}"
  puts "The PayID may already be registered or request is invalid"
  
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

## Configuration

PayIDs use the `va_base` endpoint, which is automatically configured based on your environment:

### Prelive Environment

```ruby
ZaiPayment.configure do |config|
  config.environment = :prelive
  # Uses: https://sandbox.au-0000.api.assemblypay.com
end
```

### Production Environment

```ruby
ZaiPayment.configure do |config|
  config.environment = :production
  # Uses: https://secure.api.promisepay.com
end
```

The PayId resource automatically uses the correct endpoint based on your configuration.

## Best Practices

### 1. Use Meaningful Names

Use descriptive names in the details to help customers confirm the recipient:

```ruby
# Good
details: {
  pay_id_name: 'Acme Corporation',
  owner_legal_name: 'Acme Corporation Pty Ltd'
}

# Avoid
details: {
  pay_id_name: 'Acc1',
  owner_legal_name: 'A'
}
```

### 2. Validate Email Format

Pre-validate the email format before registration:

```ruby
def valid_email?(email)
  email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
end

pay_id = 'customer@example.com'

if valid_email?(pay_id)
  # Proceed with registration
else
  puts "Invalid email format"
end
```

### 3. Store PayID Details

Always store the PayID details in your database:

```ruby
response = pay_ids.create(virtual_account_id, pay_id: email, type: 'EMAIL', details: details)

if response.success?
  pay_id = response.data
  
  # Store in database
  PayIdRecord.create!(
    external_id: pay_id['id'],
    virtual_account_id: virtual_account_id,
    pay_id: pay_id['pay_id'],
    pay_id_type: pay_id['type'],
    pay_id_name: pay_id['details']['pay_id_name'],
    owner_legal_name: pay_id['details']['owner_legal_name'],
    status: pay_id['status']
  )
end
```

### 4. Handle Errors Gracefully

Always implement proper error handling:

```ruby
def register_pay_id_safely(virtual_account_id, pay_id_email, details)
  pay_ids = ZaiPayment::Resources::PayId.new
  
  begin
    response = pay_ids.create(
      virtual_account_id,
      pay_id: pay_id_email,
      type: 'EMAIL',
      details: details
    )
    { success: true, data: response.data }
  rescue ZaiPayment::Errors::ValidationError => e
    { success: false, error: 'validation', message: e.message }
  rescue ZaiPayment::Errors::NotFoundError => e
    { success: false, error: 'not_found', message: e.message }
  rescue ZaiPayment::Errors::BadRequestError => e
    { success: false, error: 'bad_request', message: e.message }
  rescue ZaiPayment::Errors::ApiError => e
    { success: false, error: 'api_error', message: e.message }
  end
end
```

### 5. Verify Virtual Account Exists

Check that the virtual account exists before registering a PayID:

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

begin
  # Verify virtual account exists
  va_response = virtual_accounts.show(virtual_account_id)
  
  if va_response.success? && va_response.data['status'] == 'active'
    # Proceed with PayID registration
    pay_ids.create(virtual_account_id, pay_id: email, type: 'EMAIL', details: details)
  else
    puts "Virtual account is not active yet"
  end
rescue ZaiPayment::Errors::NotFoundError
  puts "Virtual account does not exist"
end
```

### 6. Monitor PayID Status

After registration, monitor the PayID status:

```ruby
pay_id = response.data

case pay_id['status']
when 'pending_activation'
  puts "PayID registered, awaiting activation"
when 'active'
  puts "PayID is active and ready to receive payments"
when 'inactive'
  puts "PayID is inactive"
else
  puts "Unknown status: #{pay_id['status']}"
end
```

### 7. Secure PayID Information

Treat PayID details as sensitive payment information:

```ruby
# Don't log sensitive details in production
if Rails.env.production?
  logger.info "PayID registered: #{pay_id['id']}"
else
  logger.debug "PayID details: #{pay_id.inspect}"
end

# Use HTTPS for all communications
# Store securely in your database
# Limit access to authorized personnel only
```

## Testing

For testing in prelive environment:

```ruby
# spec/services/pay_id_service_spec.rb
require 'spec_helper'

RSpec.describe PayIdService do
  let(:virtual_account_id) { 'test-virtual-account-id' }
  
  describe '#register_pay_id' do
    it 'registers a PayID successfully' do
      VCR.use_cassette('pay_id_register') do
        service = PayIdService.new
        result = service.register_pay_id(
          virtual_account_id,
          pay_id: 'test@example.com',
          details: {
            pay_id_name: 'Test User',
            owner_legal_name: 'Test User Full Name'
          }
        )
        
        expect(result[:success]).to be true
        expect(result[:pay_id]['id']).to be_present
        expect(result[:pay_id]['pay_id']).to eq('test@example.com')
        expect(result[:pay_id]['type']).to eq('EMAIL')
      end
    end
  end
end
```

## Troubleshooting

### Issue: ValidationError - "virtual_account_id is required"

**Solution**: Ensure you're passing a valid virtual account ID:

```ruby
# Wrong
pay_ids.create('', pay_id: 'test@example.com', type: 'EMAIL', details: {})

# Correct
pay_ids.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', pay_id: 'test@example.com', type: 'EMAIL', details: {})
```

### Issue: NotFoundError - "Virtual account not found"

**Solution**: Verify the virtual account exists before registering a PayID:

```ruby
# Check virtual account exists first
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
begin
  va_response = virtual_accounts.show(virtual_account_id)
  if va_response.success?
    # Virtual account exists, proceed with PayID registration
    pay_ids.create(virtual_account_id, pay_id: 'test@example.com', type: 'EMAIL', details: {})
  end
rescue ZaiPayment::Errors::NotFoundError
  puts "Virtual account does not exist"
end
```

### Issue: ValidationError - "pay_id must be 256 characters or less"

**Solution**: Ensure the PayID (email) is not too long:

```ruby
pay_id_email = 'verylongemail@example.com'

if pay_id_email.length <= 256
  pay_ids.create(virtual_account_id, pay_id: pay_id_email, type: 'EMAIL', details: {})
else
  puts "PayID is too long"
end
```

### Issue: ValidationError - "type must be one of: EMAIL"

**Solution**: Ensure you're using a valid type:

```ruby
# Wrong
pay_ids.create(virtual_account_id, pay_id: 'test@example.com', type: 'PHONE', details: {})

# Correct
pay_ids.create(virtual_account_id, pay_id: 'test@example.com', type: 'EMAIL', details: {})
```

### Issue: BadRequestError - PayID already registered

**Solution**: PayIDs must be unique. Check if the PayID is already registered:

```ruby
begin
  pay_ids.create(virtual_account_id, pay_id: 'test@example.com', type: 'EMAIL', details: {})
rescue ZaiPayment::Errors::BadRequestError => e
  if e.message.include?('already registered')
    puts "This PayID is already registered to another account"
  else
    puts "Bad request: #{e.message}"
  end
end
```

## See Also

- [Virtual Accounts Documentation](virtual_accounts.md)
- [Examples](../examples/pay_ids.md)
- [Zai API Documentation](https://developer.hellozai.com/docs)

