# Virtual Account Management Examples

This document provides practical examples for managing virtual accounts in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Create Virtual Account Example](#create-virtual-account-example)
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

## Create Virtual Account Example

### Example 1: Create a Basic Virtual Account

Create a virtual account for a given wallet account with a name.

```ruby
# Create virtual account
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.create(
  'ae07556e-22ef-11eb-adc1-0242ac120002',  # wallet_account_id
  account_name: 'Real Estate Agency X'
)

if response.success?
  virtual_account = response.data
  puts "Virtual Account Created!"
  puts "ID: #{virtual_account['id']}"
  puts "Account Name: #{virtual_account['account_name']}"
  puts "Routing Number: #{virtual_account['routing_number']}"
  puts "Account Number: #{virtual_account['account_number']}"
  puts "Currency: #{virtual_account['currency']}"
  puts "Status: #{virtual_account['status']}"
  puts "Created At: #{virtual_account['created_at']}"
else
  puts "Failed to create virtual account"
  puts "Error: #{response.error}"
end
```

### Example 2: Create Virtual Account with AKA Names

Create a virtual account with alternative names (AKA names) for CoP lookups.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.create(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  account_name: 'Real Estate Agency X',
  aka_names: ['Realestate agency X', 'RE Agency X', 'Agency X']
)

if response.success?
  virtual_account = response.data
  puts "Virtual Account Created!"
  puts "ID: #{virtual_account['id']}"
  puts "Account Name: #{virtual_account['account_name']}"
  puts "AKA Names: #{virtual_account['aka_names'].join(', ')}"
  puts "Routing Number: #{virtual_account['routing_number']}"
  puts "Account Number: #{virtual_account['account_number']}"
  puts "Merchant ID: #{virtual_account['merchant_id']}"
else
  puts "Failed to create virtual account"
  puts "Error: #{response.error}"
end
```

### Example 3: Using Convenience Method

Use the convenience method from ZaiPayment module.

```ruby
# Using convenience accessor
response = ZaiPayment.virtual_accounts.create(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  account_name: 'Property Management Co',
  aka_names: ['PropMgmt Co']
)

if response.success?
  puts "Virtual Account ID: #{response.data['id']}"
  puts "Status: #{response.data['status']}"
end
```

### Example 4: Complete Workflow

Complete workflow showing user creation, wallet account reference, and virtual account creation.

```ruby
begin
  # Assume we already have a wallet account ID from previous steps
  wallet_account_id = 'ae07556e-22ef-11eb-adc1-0242ac120002'
  
  # Create virtual account
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  response = virtual_accounts.create(
    wallet_account_id,
    account_name: 'Real Estate Trust Account',
    aka_names: ['RE Trust', 'Trust Account']
  )
  
  if response.success?
    virtual_account = response.data
    
    # Store important information
    virtual_account_id = virtual_account['id']
    routing_number = virtual_account['routing_number']
    account_number = virtual_account['account_number']
    
    puts "✓ Virtual Account Created Successfully!"
    puts "─" * 50
    puts "Virtual Account ID: #{virtual_account_id}"
    puts "Wallet Account ID: #{virtual_account['wallet_account_id']}"
    puts "User External ID: #{virtual_account['user_external_id']}"
    puts ""
    puts "Banking Details:"
    puts "  Account Name: #{virtual_account['account_name']}"
    puts "  Routing Number: #{routing_number}"
    puts "  Account Number: #{account_number}"
    puts "  Currency: #{virtual_account['currency']}"
    puts ""
    puts "Additional Information:"
    puts "  Status: #{virtual_account['status']}"
    puts "  Account Type: #{virtual_account['account_type']}"
    puts "  Full Legal Name: #{virtual_account['full_legal_account_name']}"
    puts "  AKA Names: #{virtual_account['aka_names'].join(', ')}"
    puts "  Merchant ID: #{virtual_account['merchant_id']}"
    puts "─" * 50
    
    # Now customers can transfer funds using these details
    puts "\nCustomers can transfer funds to:"
    puts "  BSB: #{routing_number}"
    puts "  Account: #{account_number}"
    puts "  Name: #{virtual_account['account_name']}"
  end
  
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
  puts "Please check your input parameters"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Not Found: #{e.message}"
  puts "The wallet account may not exist"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Unauthorized: #{e.message}"
  puts "Please check your API credentials"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

## Common Patterns

### Pattern 1: Validate Parameters Before Creating

```ruby
def create_virtual_account(wallet_account_id, account_name, aka_names = [])
  # Validate inputs
  raise ArgumentError, 'wallet_account_id cannot be empty' if wallet_account_id.nil? || wallet_account_id.empty?
  raise ArgumentError, 'account_name cannot be empty' if account_name.nil? || account_name.empty?
  raise ArgumentError, 'account_name too long (max 140 chars)' if account_name.length > 140
  raise ArgumentError, 'too many aka_names (max 3)' if aka_names.length > 3
  
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  params = { account_name: account_name }
  params[:aka_names] = aka_names unless aka_names.empty?
  
  response = virtual_accounts.create(wallet_account_id, **params)
  
  if response.success?
    response.data
  else
    nil
  end
end

# Usage
virtual_account = create_virtual_account(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  'My Business Account',
  ['Business', 'Company Account']
)

puts "Created: #{virtual_account['id']}" if virtual_account
```

### Pattern 2: Store Virtual Account Details

```ruby
class VirtualAccountManager
  attr_reader :virtual_accounts
  
  def initialize
    @virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  end
  
  def create_and_store(wallet_account_id, account_name, aka_names = [])
    response = virtual_accounts.create(
      wallet_account_id,
      account_name: account_name,
      aka_names: aka_names
    )
    
    return nil unless response.success?
    
    virtual_account = response.data
    
    # Store in your database
    store_in_database(virtual_account)
    
    virtual_account
  end
  
  private
  
  def store_in_database(virtual_account)
    # Example: Store in your application database
    # VirtualAccountRecord.create!(
    #   external_id: virtual_account['id'],
    #   wallet_account_id: virtual_account['wallet_account_id'],
    #   routing_number: virtual_account['routing_number'],
    #   account_number: virtual_account['account_number'],
    #   account_name: virtual_account['account_name'],
    #   status: virtual_account['status']
    # )
    puts "Storing virtual account #{virtual_account['id']} in database..."
  end
end

# Usage
manager = VirtualAccountManager.new
virtual_account = manager.create_and_store(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  'Client Trust Account'
)
```

### Pattern 3: Handle Different Response Scenarios

```ruby
def create_virtual_account_with_handling(wallet_account_id, account_name, aka_names = [])
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    response = virtual_accounts.create(
      wallet_account_id,
      account_name: account_name,
      aka_names: aka_names
    )
    
    {
      success: true,
      virtual_account: response.data,
      message: 'Virtual account created successfully'
    }
  rescue ZaiPayment::Errors::ValidationError => e
    {
      success: false,
      error: 'validation_error',
      message: e.message
    }
  rescue ZaiPayment::Errors::NotFoundError => e
    {
      success: false,
      error: 'not_found',
      message: 'Wallet account not found'
    }
  rescue ZaiPayment::Errors::BadRequestError => e
    {
      success: false,
      error: 'bad_request',
      message: e.message
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      error: 'api_error',
      message: e.message
    }
  end
end

# Usage
result = create_virtual_account_with_handling(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  'Test Account'
)

if result[:success]
  puts "Success! Virtual Account ID: #{result[:virtual_account]['id']}"
else
  puts "Error (#{result[:error]}): #{result[:message]}"
end
```

### Pattern 4: Batch Virtual Account Creation

```ruby
def create_multiple_virtual_accounts(wallet_account_id, account_configs)
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  results = []
  
  account_configs.each do |config|
    begin
      response = virtual_accounts.create(
        wallet_account_id,
        account_name: config[:account_name],
        aka_names: config[:aka_names] || []
      )
      
      if response.success?
        results << {
          success: true,
          name: config[:account_name],
          virtual_account: response.data
        }
      else
        results << {
          success: false,
          name: config[:account_name],
          error: 'Creation failed'
        }
      end
    rescue ZaiPayment::Errors::ApiError => e
      results << {
        success: false,
        name: config[:account_name],
        error: e.message
      }
    end
    
    # Be nice to the API - small delay between requests
    sleep(0.5)
  end
  
  results
end

# Usage
configs = [
  { account_name: 'Property 123 Trust', aka_names: ['Prop 123'] },
  { account_name: 'Property 456 Trust', aka_names: ['Prop 456'] },
  { account_name: 'Property 789 Trust', aka_names: ['Prop 789'] }
]

results = create_multiple_virtual_accounts(
  'ae07556e-22ef-11eb-adc1-0242ac120002',
  configs
)

successes = results.count { |r| r[:success] }
puts "Created #{successes} out of #{results.length} virtual accounts"

results.each do |result|
  if result[:success]
    puts "✓ #{result[:name]}: #{result[:virtual_account]['id']}"
  else
    puts "✗ #{result[:name]}: #{result[:error]}"
  end
end
```

## Error Handling

### Common Errors and Solutions

```ruby
begin
  response = ZaiPayment.virtual_accounts.create(
    wallet_account_id,
    account_name: 'Test Account'
  )
rescue ZaiPayment::Errors::ValidationError => e
  # Handle validation errors
  # - wallet_account_id is blank
  # - account_name is blank or too long
  # - aka_names is not an array or has more than 3 items
  puts "Validation Error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  # Handle not found errors
  # - wallet account does not exist
  puts "Not Found: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  # Handle authentication errors
  # - Invalid credentials
  # - Expired token
  puts "Unauthorized: #{e.message}"
rescue ZaiPayment::Errors::ForbiddenError => e
  # Handle authorization errors
  # - Insufficient permissions
  puts "Forbidden: #{e.message}"
rescue ZaiPayment::Errors::BadRequestError => e
  # Handle bad request errors
  # - Invalid request format
  puts "Bad Request: #{e.message}"
rescue ZaiPayment::Errors::TimeoutError => e
  # Handle timeout errors
  puts "Timeout: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  # Handle general API errors
  puts "API Error: #{e.message}"
end
```

## Best Practices

1. **Always validate input** before making API calls
2. **Handle errors gracefully** with proper error messages
3. **Store virtual account details** in your database for reference
4. **Use meaningful account names** that help identify the purpose
5. **Add AKA names** when you need multiple name variations for CoP lookups
6. **Monitor account status** after creation (should be `pending_activation`)
7. **Keep routing and account numbers secure** - they're like bank account details
8. **Use environment variables** for sensitive configuration
9. **Test in prelive environment** before using in production
10. **Implement proper logging** for audit trails

