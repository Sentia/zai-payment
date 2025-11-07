# Virtual Account Management

The VirtualAccount resource provides methods for creating and managing Zai virtual accounts for Australian payments.

## Overview

Virtual Accounts are bank account details that can be created for a wallet account, allowing users to receive funds via standard bank transfers. Each virtual account has unique BSB (routing number) and account number details that can be shared with customers or partners to receive payments.

Virtual accounts are particularly useful for:
- Receiving payments from customers via direct bank transfer
- Creating unique account details for different payment purposes
- Enabling Confirmation of Payee (CoP) lookups with account name and AKA names
- Managing trust accounts in real estate or property management

## Key Features

- **Unique Banking Details**: Each virtual account gets unique BSB and account number
- **AKA Names**: Support for alternative names (up to 3) for CoP lookups
- **Automatic Linking**: Virtual accounts are automatically linked to wallet accounts
- **Status Tracking**: Monitor account status (pending_activation, active, etc.)
- **Multiple Currencies**: Support for different currencies (primarily AUD)

## References

- [Virtual Accounts API](https://developer.hellozai.com/reference)
- [Zai API Documentation](https://developer.hellozai.com/docs)

## Usage

### Initialize the VirtualAccount Resource

```ruby
# Using a new instance
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

# Or use with custom client
client = ZaiPayment::Client.new(base_endpoint: :va_base)
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new(client: client)

# Or use the convenience method
ZaiPayment.virtual_accounts
```

## Methods

### List Virtual Accounts

List all Virtual Accounts for a given Wallet Account. This retrieves an array of all virtual accounts associated with the wallet account.

#### Parameters

- `wallet_account_id` (required) - The wallet account ID

#### Example

```ruby
# List all virtual accounts for a wallet
response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')

# Access the list of virtual accounts
if response.success?
  accounts = response.data  # Array of virtual accounts
  total = response.meta['total']
  
  puts "Found #{accounts.length} virtual accounts"
  
  accounts.each do |account|
    puts "ID: #{account['id']}"
    puts "Name: #{account['account_name']}"
    puts "BSB: #{account['routing_number']}"
    puts "Account: #{account['account_number']}"
    puts "Status: #{account['status']}"
  end
end
```

#### Response

```ruby
{
  "virtual_accounts" => [
    {
      "id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "routing_number" => "123456",
      "account_number" => "100000017",
      "wallet_account_id" => "ae07556e-22ef-11eb-adc1-0242ac120002",
      "user_external_id" => "ca12346e-22ef-11eb-adc1-0242ac120002",
      "currency" => "AUD",
      "status" => "active",
      "created_at" => "2020-04-27T20:28:22.378Z",
      "updated_at" => "2020-04-27T20:28:22.378Z",
      "account_type" => "NIND",
      "full_legal_account_name" => "Prop Tech Marketplace",
      "account_name" => "Real Estate Agency X",
      "aka_names" => ["Realestate agency X"],
      "merchant_id" => "46deb476c1a641eb8eb726a695bbe5bc"
    },
    {
      "id" => "aaaaaaaa-cccc-dddd-eeee-ffffffffffff",
      "routing_number" => "123456",
      "account_number" => "100000025",
      "currency" => "AUD",
      "wallet_account_id" => "ae07556e-22ef-11eb-adc1-0242ac120002",
      "user_external_id" => "ca12346e-22ef-11eb-adc1-0242ac120002",
      "status" => "pending_activation",
      "created_at" => "2020-04-27T20:28:22.378Z",
      "updated_at" => "2020-04-27T20:28:22.378Z",
      "account_type" => "NIND",
      "full_legal_account_name" => "Prop Tech Marketplace",
      "account_name" => "Real Estate Agency X",
      "aka_names" => ["Realestate agency X"],
      "merchant_id" => "46deb476c1a641eb8eb726a695bbe5bc"
    }
  ],
  "meta" => {
    "total" => 2
  }
}
```

**Response Fields:**

The response contains an array of virtual account objects. Each object has the same fields as described in the Create Virtual Account section.

**Additional Response Data:**

- `meta` - Contains pagination and metadata information
  - `total` - Total number of virtual accounts

**Use Cases:**

- Retrieve all virtual accounts for auditing purposes
- Display available payment accounts to customers
- Filter accounts by status (active, pending_activation, etc.)
- Check if virtual accounts exist before creating new ones
- Monitor account statuses across multiple properties
- Generate reports on virtual account usage

### Show Virtual Account

Show details of a specific Virtual Account using the given virtual account ID.

#### Parameters

- `virtual_account_id` (required) - The virtual account ID

#### Example

```ruby
# Get specific virtual account details
response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

# Access virtual account details
if response.success?
  account = response.data
  
  puts "Virtual Account: #{account['account_name']}"
  puts "Status: #{account['status']}"
  puts "BSB: #{account['routing_number']}"
  puts "Account Number: #{account['account_number']}"
  puts "Currency: #{account['currency']}"
  
  # Access AKA names
  account['aka_names'].each do |aka_name|
    puts "AKA: #{aka_name}"
  end
end
```

#### Response

```ruby
{
  "virtual_accounts" => {
    "id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
    "routing_number" => "123456",
    "account_number" => "100000017",
    "currency" => "AUD",
    "user_external_id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
    "wallet_account_id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc",
    "status" => "active",
    "created_at" => "2020-04-27T20:28:22.378Z",
    "updated_at" => "2020-04-27T20:28:22.378Z",
    "account_type" => "NIND",
    "full_legal_account_name" => "Prop Tech Marketplace",
    "account_name" => "Real Estate Agency X",
    "aka_names" => [
      "Realestate Agency X",
      "Realestate Agency X of PropTech Marketplace"
    ],
    "merchant_id" => "46deb476c1a641eb8eb726a695bbe5bc"
  }
}
```

**Response Fields:**

The response contains a single virtual account object with all the fields described in the Create Virtual Account section.

**Use Cases:**

- Verify virtual account details before sharing with customers
- Check account status before processing payments
- Generate payment instructions for customers
- Audit specific virtual account configurations
- Validate account information
- Monitor individual account updates

### Create Virtual Account

Create a Virtual Account for a given Wallet Account. This generates unique bank account details that can be used to receive funds.

#### Parameters

- `wallet_account_id` (required) - The wallet account ID
- `account_name` (required) - A name for the virtual account (max 140 characters)
- `aka_names` (optional) - Array of alternative names for CoP lookups (0 to 3 items)

#### Example

```ruby
# Basic creation with account name only
response = virtual_accounts.create(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  account_name: 'Real Estate Agency X'
)

# With AKA names for Confirmation of Payee
response = virtual_accounts.create(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  account_name: 'Real Estate Agency X',
  aka_names: ['Realestate agency X', 'RE Agency X', 'Agency X']
)

# Access virtual account details
if response.success?
  virtual_account = response.data
  puts "Virtual Account ID: #{virtual_account['id']}"
  puts "BSB: #{virtual_account['routing_number']}"
  puts "Account Number: #{virtual_account['account_number']}"
  puts "Account Name: #{virtual_account['account_name']}"
  puts "Status: #{virtual_account['status']}"
end
```

#### Response

```ruby
{
  "virtual_accounts" => {
    "id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "routing_number" => "123456",
    "account_number" => "100000017",
    "currency" => "AUD",
    "wallet_account_id" => "ae07556e-22ef-11eb-adc1-0242ac120002",
    "user_external_id" => "ca12346e-22ef-11eb-adc1-0242ac120002",
    "status" => "pending_activation",
    "created_at" => "2020-04-27T20:28:22.378Z",
    "updated_at" => "2020-04-27T20:28:22.378Z",
    "account_type" => "NIND",
    "full_legal_account_name" => "Prop Tech Marketplace",
    "account_name" => "Real Estate Agency X",
    "aka_names" => ["Realestate agency X"],
    "merchant_id" => "46deb476c1a641eb8eb726a695bbe5bc"
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier for the virtual account |
| `routing_number` | String | BSB/routing number (6 digits) |
| `account_number` | String | Bank account number |
| `currency` | String | Account currency (e.g., "AUD") |
| `wallet_account_id` | String | Associated wallet account ID |
| `user_external_id` | String | Associated user's external ID |
| `status` | String | Account status (pending_activation, active, etc.) |
| `created_at` | String | ISO 8601 timestamp of creation |
| `updated_at` | String | ISO 8601 timestamp of last update |
| `account_type` | String | Type of account (e.g., "NIND") |
| `full_legal_account_name` | String | Full legal name of the account |
| `account_name` | String | Display name of the account |
| `aka_names` | Array | Alternative names for CoP lookups |
| `merchant_id` | String | Merchant identifier |

**Use Cases:**

- Create unique payment collection accounts for different properties or services
- Enable customers to pay via direct bank transfer
- Set up trust accounts for real estate transactions
- Configure multiple name variations for better Confirmation of Payee matching
- Generate dedicated account details for recurring payment arrangements

## Validation Rules

### account_name

- **Required**: Yes
- **Type**: String
- **Max Length**: 140 characters
- **Description**: The display name for the virtual account. This is used in CoP lookups and shown to customers when confirming payments.

### aka_names

- **Required**: No
- **Type**: Array of Strings
- **Min Items**: 0
- **Max Items**: 3
- **Description**: Alternative names for the virtual account. These are used in Confirmation of Payee (CoP) lookups to improve matching when customers initiate transfers.

### wallet_account_id

- **Required**: Yes
- **Type**: String (UUID)
- **Description**: The ID of the wallet account that this virtual account will be linked to. The wallet account must exist before creating a virtual account.

## Error Handling

The virtual account methods can raise the following errors:

### ZaiPayment::Errors::ValidationError

Raised when input parameters fail validation:

```ruby
begin
  response = virtual_accounts.create(
    '',  # Empty wallet_account_id
    account_name: 'Test Account'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # Output: "wallet_account_id is required and cannot be blank"
end
```

**Common validation errors:**
- `wallet_account_id is required and cannot be blank`
- `account_name cannot be blank`
- `account_name must be 140 characters or less`
- `aka_names must be an array`
- `aka_names must contain between 0 and 3 items`

### ZaiPayment::Errors::NotFoundError

Raised when the wallet account doesn't exist:

```ruby
begin
  response = virtual_accounts.create(
    'invalid-wallet-id',
    account_name: 'Test Account'
  )
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Not found: #{e.message}"
end
```

### ZaiPayment::Errors::UnauthorizedError

Raised when authentication fails:

```ruby
begin
  response = virtual_accounts.create(
    wallet_account_id,
    account_name: 'Test Account'
  )
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication failed: #{e.message}"
  # Check your API credentials
end
```

### ZaiPayment::Errors::BadRequestError

Raised when the request is malformed or contains invalid data:

```ruby
begin
  response = virtual_accounts.create(
    wallet_account_id,
    account_name: 'Test Account'
  )
rescue ZaiPayment::Errors::BadRequestError => e
  puts "Bad request: #{e.message}"
end
```

## Complete Example

Here's a complete workflow showing how to list and create virtual accounts with proper error handling:

```ruby
require 'zai_payment'

# Configure ZaiPayment
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID']
  config.client_secret = ENV['ZAI_CLIENT_SECRET']
  config.scope = ENV['ZAI_SCOPE']
end

# Initialize resource
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
wallet_account_id = 'ae07556e-22ef-11eb-adc1-0242ac120002'

begin
  # First, list existing virtual accounts
  puts "Fetching existing virtual accounts..."
  list_response = virtual_accounts.list(wallet_account_id)
  
  if list_response.success?
    existing_accounts = list_response.data
    puts "✓ Found #{existing_accounts.length} existing virtual account(s)"
    
    # Display existing accounts
    existing_accounts.each do |account|
      puts "  - #{account['account_name']} (#{account['status']})"
      puts "    BSB: #{account['routing_number']} | Account: #{account['account_number']}"
    end
    
    # Check if we need to create a new one
    property_name = 'Property 123 Trust Account'
    existing = existing_accounts.find { |a| a['account_name'] == property_name }
    
    if existing
      puts "\n✓ Virtual account already exists for '#{property_name}'"
      puts "  ID: #{existing['id']}"
      puts "  Status: #{existing['status']}"
    else
      puts "\nCreating new virtual account for '#{property_name}'..."
      
      # Create new virtual account
      create_response = virtual_accounts.create(
        wallet_account_id,
        account_name: property_name,
        aka_names: ['Prop 123', 'Property Trust', 'Trust 123']
      )
      
      if create_response.success?
        virtual_account = create_response.data
        
        puts "✓ Virtual Account Created Successfully!"
        puts "─" * 60
        puts "ID: #{virtual_account['id']}"
        puts "Status: #{virtual_account['status']}"
        puts ""
        puts "Bank Details (share with customers):"
        puts "  BSB: #{virtual_account['routing_number']}"
        puts "  Account: #{virtual_account['account_number']}"
        puts "  Name: #{virtual_account['account_name']}"
        puts ""
        puts "Alternative Names for CoP:"
        virtual_account['aka_names'].each do |aka_name|
          puts "  - #{aka_name}"
        end
        puts "─" * 60
        
        # Store the details in your database for future reference
        # YourDatabase.store_virtual_account(virtual_account)
      else
        puts "Failed to create virtual account"
      end
    end
  else
    puts "Failed to list virtual accounts"
  end

rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
  puts "Please check your input parameters"
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Wallet Account Not Found: #{e.message}"
  puts "Please verify the wallet_account_id exists"
  
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication Failed: #{e.message}"
  puts "Please check your API credentials"
  
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

## Configuration

Virtual accounts use the `va_base` endpoint, which is automatically configured based on your environment:

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

The VirtualAccount resource automatically uses the correct endpoint based on your configuration.

## Best Practices

### 1. Meaningful Account Names

Use descriptive account names that help identify the purpose:

```ruby
# Good
account_name: 'Property 123 Main St Trust Account'
account_name: 'Client Settlement Fund - Smith'
account_name: 'Rent Collection - Building A'

# Avoid
account_name: 'Account 1'
account_name: 'Test'
```

### 2. Effective AKA Names

Add variations that customers might use when searching:

```ruby
aka_names: [
  'Smith Real Estate',           # Full name
  'Smith RE',                     # Abbreviation
  'Smith Property Management'    # Alternative name
]
```

### 3. Store Virtual Account Details

Always store the virtual account details in your database:

```ruby
response = virtual_accounts.create(wallet_account_id, account_name: name)

if response.success?
  virtual_account = response.data
  
  # Store in database
  VirtualAccountRecord.create!(
    external_id: virtual_account['id'],
    routing_number: virtual_account['routing_number'],
    account_number: virtual_account['account_number'],
    account_name: virtual_account['account_name'],
    wallet_account_id: virtual_account['wallet_account_id'],
    status: virtual_account['status']
  )
end
```

### 4. Handle Errors Gracefully

Always implement proper error handling:

```ruby
def create_virtual_account_safely(wallet_account_id, params)
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    response = virtual_accounts.create(wallet_account_id, **params)
    { success: true, data: response.data }
  rescue ZaiPayment::Errors::ValidationError => e
    { success: false, error: 'validation', message: e.message }
  rescue ZaiPayment::Errors::NotFoundError => e
    { success: false, error: 'not_found', message: e.message }
  rescue ZaiPayment::Errors::ApiError => e
    { success: false, error: 'api_error', message: e.message }
  end
end
```

### 5. Validate Before Creating

Pre-validate input to provide better user feedback:

```ruby
def validate_virtual_account_params(account_name, aka_names)
  errors = []
  
  if account_name.nil? || account_name.strip.empty?
    errors << 'Account name is required'
  elsif account_name.length > 140
    errors << 'Account name must be 140 characters or less'
  end
  
  if aka_names && !aka_names.is_a?(Array)
    errors << 'AKA names must be an array'
  elsif aka_names && aka_names.length > 3
    errors << 'Maximum 3 AKA names allowed'
  end
  
  errors
end

# Usage
errors = validate_virtual_account_params(account_name, aka_names)
if errors.empty?
  # Proceed with creation
else
  puts "Validation errors: #{errors.join(', ')}"
end
```

### 6. Monitor Virtual Account Status

After creation, monitor the status of the virtual account:

```ruby
virtual_account = response.data

case virtual_account['status']
when 'pending_activation'
  puts "Account created, awaiting activation"
when 'active'
  puts "Account is active and ready to receive funds"
when 'inactive'
  puts "Account is inactive"
else
  puts "Unknown status: #{virtual_account['status']}"
end
```

### 7. Secure Banking Details

Treat virtual account details like real bank account information:

```ruby
# Don't log sensitive details in production
if Rails.env.production?
  logger.info "Virtual account created: #{virtual_account['id']}"
else
  logger.debug "Virtual account details: #{virtual_account.inspect}"
end

# Use HTTPS for all communications
# Store securely in your database
# Limit access to authorized personnel only
```

## Testing

For testing in prelive environment:

```ruby
# spec/services/virtual_account_service_spec.rb
require 'spec_helper'

RSpec.describe VirtualAccountService do
  let(:wallet_account_id) { 'test-wallet-id' }
  
  describe '#create_virtual_account' do
    it 'creates a virtual account successfully' do
      VCR.use_cassette('virtual_account_create') do
        service = VirtualAccountService.new
        result = service.create_virtual_account(
          wallet_account_id,
          account_name: 'Test Account',
          aka_names: ['Test']
        )
        
        expect(result[:success]).to be true
        expect(result[:virtual_account]['id']).to be_present
        expect(result[:virtual_account]['routing_number']).to be_present
        expect(result[:virtual_account]['account_number']).to be_present
      end
    end
  end
end
```

## Troubleshooting

### Issue: ValidationError - "wallet_account_id is required"

**Solution**: Ensure you're passing a valid wallet account ID:

```ruby
# Wrong
virtual_accounts.create('', account_name: 'Test')

# Correct
virtual_accounts.create('ae07556e-22ef-11eb-adc1-0242ac120002', account_name: 'Test')
```

### Issue: NotFoundError - "Wallet account not found"

**Solution**: Verify the wallet account exists before creating a virtual account:

```ruby
# Check wallet account exists first
wallet_accounts = ZaiPayment::Resources::WalletAccount.new
begin
  wallet_response = wallet_accounts.show(wallet_account_id)
  if wallet_response.success?
    # Wallet exists, proceed with virtual account creation
    virtual_accounts.create(wallet_account_id, account_name: 'Test')
  end
rescue ZaiPayment::Errors::NotFoundError
  puts "Wallet account does not exist"
end
```

### Issue: ValidationError - "account_name must be 140 characters or less"

**Solution**: Truncate or shorten the account name:

```ruby
account_name = "Very Long Account Name That Exceeds The Maximum Length"

# Truncate to 140 characters
truncated_name = account_name[0, 140]

virtual_accounts.create(wallet_account_id, account_name: truncated_name)
```

### Issue: ValidationError - "aka_names must contain between 0 and 3 items"

**Solution**: Limit to maximum 3 AKA names:

```ruby
# Wrong
aka_names = ['Name 1', 'Name 2', 'Name 3', 'Name 4']

# Correct - take first 3
aka_names = ['Name 1', 'Name 2', 'Name 3']

virtual_accounts.create(
  wallet_account_id,
  account_name: 'Test',
  aka_names: aka_names[0, 3]  # Ensure max 3 items
)
```

## See Also

- [Wallet Accounts Documentation](wallet_accounts.md)
- [Examples](../examples/virtual_accounts.md)
- [Zai API Documentation](https://developer.hellozai.com/docs)

