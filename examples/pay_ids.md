# PayID Management Examples

This document provides practical examples for managing PayIDs in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Register PayID Example](#register-payid-example)
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

## Register PayID Example

### Example 1: Register an EMAIL PayID

Register a PayID for a given virtual account.

```ruby
# Register PayID
pay_ids = ZaiPayment::Resources::PayId.new

response = pay_ids.create(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',  # virtual_account_id
  pay_id: 'jsmith@mydomain.com',
  type: 'EMAIL',
  details: {
    pay_id_name: 'J Smith',
    owner_legal_name: 'Mr John Smith'
  }
)

if response.success?
  pay_id = response.data
  puts "PayID Registered!"
  puts "ID: #{pay_id['id']}"
  puts "PayID: #{pay_id['pay_id']}"
  puts "Type: #{pay_id['type']}"
  puts "Status: #{pay_id['status']}"
  puts "PayID Name: #{pay_id['details']['pay_id_name']}"
  puts "Owner Legal Name: #{pay_id['details']['owner_legal_name']}"
  puts "Created At: #{pay_id['created_at']}"
else
  puts "Failed to register PayID"
  puts "Error: #{response.error}"
end
```

### Example 2: Register PayID with Error Handling

Register a PayID with comprehensive error handling.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

begin
  response = pay_ids.create(
    '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
    pay_id: 'jsmith@mydomain.com',
    type: 'EMAIL',
    details: {
      pay_id_name: 'J Smith',
      owner_legal_name: 'Mr John Smith'
    }
  )
  
  if response.success?
    pay_id = response.data
    
    puts "✓ PayID Registered Successfully!"
    puts "─" * 50
    puts "PayID ID: #{pay_id['id']}"
    puts "PayID: #{pay_id['pay_id']}"
    puts "Type: #{pay_id['type']}"
    puts "Status: #{pay_id['status']}"
    puts ""
    puts "Details:"
    puts "  PayID Name: #{pay_id['details']['pay_id_name']}"
    puts "  Owner Legal Name: #{pay_id['details']['owner_legal_name']}"
    puts ""
    puts "Links:"
    puts "  Self: #{pay_id['links']['self']}"
    puts "  Virtual Account: #{pay_id['links']['virtual_accounts']}"
    puts "─" * 50
  end
  
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
  puts "Please check your input parameters"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Not Found: #{e.message}"
  puts "The virtual account may not exist"
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Unauthorized: #{e.message}"
  puts "Please check your API credentials"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 3: Register PayID for Business Email

Register a PayID using a business email address.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

response = pay_ids.create(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  pay_id: 'payments@mybusiness.com.au',
  type: 'EMAIL',
  details: {
    pay_id_name: 'MyBusiness Pty Ltd',
    owner_legal_name: 'MyBusiness Pty Ltd'
  }
)

if response.success?
  puts "Business PayID registered successfully"
  puts "PayID: #{response.data['pay_id']}"
  puts "Status: #{response.data['status']}"
  puts "Use this PayID for receiving payments from customers"
end
```

### Example 4: Register PayID After Creating Virtual Account

Complete workflow showing virtual account creation followed by PayID registration.

```ruby
begin
  # Step 1: Create a Virtual Account
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  wallet_account_id = 'ae07556e-22ef-11eb-adc1-0242ac120002'
  
  va_response = virtual_accounts.create(
    wallet_account_id,
    account_name: 'Real Estate Trust Account',
    aka_names: ['RE Trust Account']
  )
  
  if va_response.success?
    virtual_account = va_response.data
    virtual_account_id = virtual_account['id']
    
    puts "✓ Virtual Account Created"
    puts "  ID: #{virtual_account_id}"
    puts "  BSB: #{virtual_account['routing_number']}"
    puts "  Account: #{virtual_account['account_number']}"
    
    # Step 2: Register PayID for the Virtual Account
    pay_ids = ZaiPayment::Resources::PayId.new
    
    payid_response = pay_ids.create(
      virtual_account_id,
      pay_id: 'trust@realestate.com.au',
      type: 'EMAIL',
      details: {
        pay_id_name: 'RE Trust',
        owner_legal_name: 'Real Estate Trust Account'
      }
    )
    
    if payid_response.success?
      pay_id = payid_response.data
      
      puts "\n✓ PayID Registered"
      puts "  PayID: #{pay_id['pay_id']}"
      puts "  Type: #{pay_id['type']}"
      puts "  Status: #{pay_id['status']}"
      puts ""
      puts "Customers can now send payments to:"
      puts "  PayID: #{pay_id['pay_id']}"
      puts "  OR"
      puts "  BSB: #{virtual_account['routing_number']}"
      puts "  Account: #{virtual_account['account_number']}"
    end
  end
  
rescue ZaiPayment::Errors::ApiError => e
  puts "Error: #{e.message}"
end
```

### Example 5: Validate Before Registering

Pre-validate PayID data before making the API call.

```ruby
def validate_pay_id_params(pay_id, type, details)
  errors = []
  
  # Validate pay_id
  if pay_id.nil? || pay_id.strip.empty?
    errors << 'PayID is required'
  elsif pay_id.length > 256
    errors << 'PayID must be 256 characters or less'
  elsif !pay_id.include?('@')
    errors << 'Email PayID must contain @ symbol'
  end
  
  # Validate type
  if type.nil? || type.strip.empty?
    errors << 'Type is required'
  elsif type.upcase != 'EMAIL'
    errors << 'Type must be EMAIL'
  end
  
  # Validate details
  if details.nil? || !details.is_a?(Hash)
    errors << 'Details must be a hash'
  else
    if details[:pay_id_name] && details[:pay_id_name].length > 140
      errors << 'PayID name must be 140 characters or less'
    end
    
    if details[:owner_legal_name] && details[:owner_legal_name].length > 140
      errors << 'Owner legal name must be 140 characters or less'
    end
  end
  
  errors
end

# Usage
virtual_account_id = '46deb476-c1a6-41eb-8eb7-26a695bbe5bc'
pay_id = 'customer@example.com'
type = 'EMAIL'
details = {
  pay_id_name: 'Customer Name',
  owner_legal_name: 'Customer Full Legal Name'
}

errors = validate_pay_id_params(pay_id, type, details)

if errors.empty?
  pay_ids = ZaiPayment::Resources::PayId.new
  response = pay_ids.create(
    virtual_account_id,
    pay_id: pay_id,
    type: type,
    details: details
  )
  
  puts "✓ PayID registered" if response.success?
else
  puts "✗ Validation errors:"
  errors.each { |error| puts "  - #{error}" }
end
```

### Example 6: Register Multiple PayIDs

Register PayIDs for multiple virtual accounts.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

registrations = [
  {
    virtual_account_id: '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
    pay_id: 'property1@realestate.com',
    pay_id_name: 'Property 1 Trust',
    owner_legal_name: 'Property 1 Trust Account'
  },
  {
    virtual_account_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    pay_id: 'property2@realestate.com',
    pay_id_name: 'Property 2 Trust',
    owner_legal_name: 'Property 2 Trust Account'
  }
]

results = []

puts "Registering #{registrations.length} PayIDs..."
puts "─" * 60

registrations.each_with_index do |reg, index|
  begin
    response = pay_ids.create(
      reg[:virtual_account_id],
      pay_id: reg[:pay_id],
      type: 'EMAIL',
      details: {
        pay_id_name: reg[:pay_id_name],
        owner_legal_name: reg[:owner_legal_name]
      }
    )
    
    if response.success?
      results << {
        virtual_account_id: reg[:virtual_account_id],
        pay_id: reg[:pay_id],
        success: true,
        status: response.data['status']
      }
      puts "✓ PayID #{index + 1}: #{reg[:pay_id]} - Registered"
    end
    
  rescue ZaiPayment::Errors::NotFoundError => e
    results << { virtual_account_id: reg[:virtual_account_id], success: false, error: 'Not found' }
    puts "✗ PayID #{index + 1}: #{reg[:pay_id]} - Virtual account not found"
  rescue ZaiPayment::Errors::ApiError => e
    results << { virtual_account_id: reg[:virtual_account_id], success: false, error: e.message }
    puts "✗ PayID #{index + 1}: #{reg[:pay_id]} - #{e.message}"
  end
  
  # Be nice to the API - small delay between requests
  sleep(0.5) if index < registrations.length - 1
end

puts "─" * 60
successes = results.count { |r| r[:success] }
failures = results.count { |r| !r[:success] }

puts "\nResults:"
puts "  Successful registrations: #{successes}"
puts "  Failed registrations: #{failures}"
```

## Show PayID Examples

### Example 1: Get PayID Details

Retrieve details of a specific PayID by its ID.

```ruby
# Get PayID details
pay_ids = ZaiPayment::Resources::PayId.new

response = pay_ids.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if response.success?
  pay_id = response.data
  
  puts "PayID Details:"
  puts "─" * 60
  puts "ID: #{pay_id['id']}"
  puts "PayID: #{pay_id['pay_id']}"
  puts "Type: #{pay_id['type']}"
  puts "Status: #{pay_id['status']}"
  puts ""
  puts "Details:"
  puts "  PayID Name: #{pay_id['details']['pay_id_name']}"
  puts "  Owner Legal Name: #{pay_id['details']['owner_legal_name']}"
  puts ""
  puts "Timestamps:"
  puts "  Created: #{pay_id['created_at']}"
  puts "  Updated: #{pay_id['updated_at']}"
  puts "─" * 60
else
  puts "Failed to retrieve PayID"
  puts "Error: #{response.error}"
end
```

### Example 2: Check PayID Status

Check if a PayID is active before proceeding with operations.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

begin
  response = pay_ids.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
  
  if response.success?
    pay_id = response.data
    
    case pay_id['status']
    when 'active'
      puts "✓ PayID is active and ready to receive payments"
      puts "  PayID: #{pay_id['pay_id']}"
      puts "  Type: #{pay_id['type']}"
    when 'pending_activation'
      puts "⏳ PayID is pending activation"
      puts "  Please wait for activation to complete"
    when 'deregistered'
      puts "✗ PayID has been deregistered"
      puts "  Cannot receive payments"
    else
      puts "⚠ Unknown status: #{pay_id['status']}"
    end
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "PayID not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 3: Display PayID Information to Users

Generate payment instructions for customers based on PayID details.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

response = pay_ids.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if response.success?
  pay_id = response.data
  
  if pay_id['status'] == 'active'
    puts "Payment Information"
    puts "=" * 60
    puts ""
    puts "You can send payments to:"
    puts ""
    puts "  PayID: #{pay_id['pay_id']}"
    puts "  Type: #{pay_id['type']}"
    puts "  Name: #{pay_id['details']['pay_id_name']}"
    puts ""
    puts "This PayID is registered to:"
    puts "  #{pay_id['details']['owner_legal_name']}"
    puts ""
    puts "=" * 60
  else
    puts "This PayID is not active yet."
    puts "Status: #{pay_id['status']}"
  end
end
```

### Example 4: Validate PayID Before Payment

Validate PayID details before initiating a payment.

```ruby
def validate_pay_id(pay_id_id)
  pay_ids = ZaiPayment::Resources::PayId.new
  
  begin
    response = pay_ids.show(pay_id_id)
    
    if response.success?
      pay_id = response.data
      
      # Validation checks
      errors = []
      errors << "PayID is not active" unless pay_id['status'] == 'active'
      errors << "Invalid PayID type" unless pay_id['type'] == 'EMAIL'
      
      if errors.empty?
        {
          valid: true,
          pay_id: pay_id,
          payment_info: {
            pay_id: pay_id['pay_id'],
            type: pay_id['type'],
            name: pay_id['details']['pay_id_name']
          }
        }
      else
        {
          valid: false,
          errors: errors,
          pay_id: pay_id
        }
      end
    else
      {
        valid: false,
        errors: ['Failed to retrieve PayID']
      }
    end
    
  rescue ZaiPayment::Errors::NotFoundError
    {
      valid: false,
      errors: ['PayID not found']
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      valid: false,
      errors: ["API Error: #{e.message}"]
    }
  end
end

# Usage
result = validate_pay_id('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if result[:valid]
  puts "✓ PayID is valid"
  puts "Payment Info:"
  puts "  PayID: #{result[:payment_info][:pay_id]}"
  puts "  Type: #{result[:payment_info][:type]}"
  puts "  Name: #{result[:payment_info][:name]}"
else
  puts "✗ PayID validation failed:"
  result[:errors].each { |error| puts "  - #{error}" }
end
```

### Example 5: Compare Multiple PayIDs

Retrieve and compare multiple PayIDs.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

pay_id_ids = [
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
]

puts "PayID Comparison"
puts "=" * 80

pay_id_ids.each do |pay_id_id|
  begin
    response = pay_ids.show(pay_id_id)
    
    if response.success?
      pay_id = response.data
      puts "\n#{pay_id['pay_id']}"
      puts "  ID: #{pay_id_id[0..7]}..."
      puts "  Status: #{pay_id['status']}"
      puts "  Type: #{pay_id['type']}"
      puts "  Created: #{Date.parse(pay_id['created_at']).strftime('%Y-%m-%d')}"
    end
  rescue ZaiPayment::Errors::NotFoundError
    puts "\n#{pay_id_id[0..7]}..."
    puts "  Status: Not Found"
  end
end

puts "\n#{'=' * 80}"
```

## Update PayID Status Examples

### Example 1: Deregister a PayID

Deregister a PayID by setting its status to 'deregistered'.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

begin
  response = pay_ids.update_status(
    '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
    'deregistered'
  )
  
  if response.success?
    puts "PayID deregistration initiated"
    puts "ID: #{response.data['id']}"
    puts "Message: #{response.data['message']}"
    puts "\nNote: The status update is being processed asynchronously."
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "PayID not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 2: Deregister Multiple PayIDs

Deregister multiple PayIDs in batch.

```ruby
pay_ids = ZaiPayment::Resources::PayId.new

pay_id_ids = [
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
]

results = []

pay_id_ids.each_with_index do |pay_id_id, index|
  begin
    response = pay_ids.update_status(pay_id_id, 'deregistered')
    
    if response.success?
      results << { id: pay_id_id, success: true }
      puts "✓ PayID #{index + 1}: Deregistered"
    end
    
  rescue ZaiPayment::Errors::ApiError => e
    results << { id: pay_id_id, success: false, error: e.message }
    puts "✗ PayID #{index + 1}: #{e.message}"
  end
end

puts "\nDeregistered #{results.count { |r| r[:success] }} out of #{pay_id_ids.length} PayIDs"
```

## Common Patterns

### Pattern 1: Safe PayID Registration with Retry

```ruby
def register_pay_id_safely(virtual_account_id, pay_id, details, max_retries = 3)
  pay_ids = ZaiPayment::Resources::PayId.new
  retries = 0
  
  begin
    response = pay_ids.create(
      virtual_account_id,
      pay_id: pay_id,
      type: 'EMAIL',
      details: details
    )
    
    {
      success: true,
      pay_id: response.data,
      message: 'PayID registered successfully'
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
      message: 'Virtual account not found'
    }
  rescue ZaiPayment::Errors::TimeoutError => e
    retries += 1
    if retries < max_retries
      sleep(2**retries)  # Exponential backoff
      retry
    else
      {
        success: false,
        error: 'timeout',
        message: 'Request timed out after retries'
      }
    end
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      error: 'api_error',
      message: e.message
    }
  end
end

# Usage
result = register_pay_id_safely(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'customer@example.com',
  {
    pay_id_name: 'Customer Name',
    owner_legal_name: 'Customer Full Name'
  }
)

if result[:success]
  puts "✓ Success! PayID: #{result[:pay_id]['pay_id']}"
else
  puts "✗ Failed (#{result[:error]}): #{result[:message]}"
end
```

### Pattern 2: Store PayID Details in Database

```ruby
class PayIdManager
  attr_reader :pay_ids
  
  def initialize
    @pay_ids = ZaiPayment::Resources::PayId.new
  end
  
  def register_and_store(virtual_account_id, pay_id_email, pay_id_name, owner_legal_name)
    response = pay_ids.create(
      virtual_account_id,
      pay_id: pay_id_email,
      type: 'EMAIL',
      details: {
        pay_id_name: pay_id_name,
        owner_legal_name: owner_legal_name
      }
    )
    
    return nil unless response.success?
    
    pay_id = response.data
    
    # Store in your database
    store_in_database(pay_id)
    
    pay_id
  end
  
  private
  
  def store_in_database(pay_id)
    # Example: Store in your application database
    # PayIdRecord.create!(
    #   external_id: pay_id['id'],
    #   virtual_account_id: pay_id['links']['virtual_accounts'].split('/').last,
    #   pay_id: pay_id['pay_id'],
    #   pay_id_type: pay_id['type'],
    #   pay_id_name: pay_id['details']['pay_id_name'],
    #   owner_legal_name: pay_id['details']['owner_legal_name'],
    #   status: pay_id['status']
    # )
    puts "Storing PayID #{pay_id['id']} in database..."
  end
end

# Usage
manager = PayIdManager.new
pay_id = manager.register_and_store(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'customer@example.com',
  'Customer Name',
  'Customer Full Legal Name'
)

puts "Registered and stored: #{pay_id['pay_id']}" if pay_id
```

### Pattern 3: Handle Different Response Scenarios

```ruby
def register_pay_id_with_handling(virtual_account_id, pay_id, details)
  pay_ids = ZaiPayment::Resources::PayId.new
  
  begin
    response = pay_ids.create(
      virtual_account_id,
      pay_id: pay_id,
      type: 'EMAIL',
      details: details
    )
    
    {
      success: true,
      pay_id: response.data,
      message: 'PayID registered successfully'
    }
  rescue ZaiPayment::Errors::ValidationError => e
    {
      success: false,
      error: 'validation_error',
      message: e.message,
      user_message: 'Please check the PayID and details provided'
    }
  rescue ZaiPayment::Errors::NotFoundError => e
    {
      success: false,
      error: 'not_found',
      message: 'Virtual account not found',
      user_message: 'The virtual account does not exist'
    }
  rescue ZaiPayment::Errors::BadRequestError => e
    {
      success: false,
      error: 'bad_request',
      message: e.message,
      user_message: 'Invalid request. Please check your data'
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      error: 'api_error',
      message: e.message,
      user_message: 'An error occurred. Please try again later'
    }
  end
end

# Usage
result = register_pay_id_with_handling(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'test@example.com',
  {
    pay_id_name: 'Test User',
    owner_legal_name: 'Test User Full Name'
  }
)

if result[:success]
  puts "Success! PayID: #{result[:pay_id]['pay_id']}"
  puts "Status: #{result[:pay_id]['status']}"
else
  puts "Error: #{result[:user_message]}"
  puts "Details: #{result[:message]}"
end
```

## Error Handling

### Common Errors and Solutions

```ruby
begin
  response = ZaiPayment::Resources::PayId.new.create(
    virtual_account_id,
    pay_id: 'user@example.com',
    type: 'EMAIL',
    details: {
      pay_id_name: 'User Name',
      owner_legal_name: 'User Full Name'
    }
  )
rescue ZaiPayment::Errors::ValidationError => e
  # Handle validation errors
  # - virtual_account_id is blank
  # - pay_id is blank or too long
  # - type is invalid
  # - details is missing or invalid
  puts "Validation Error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  # Handle not found errors
  # - virtual account does not exist
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
  # - PayID already registered
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
3. **Store PayID details** in your database for reference
4. **Use meaningful names** in pay_id_name and owner_legal_name
5. **Monitor PayID status** after registration (should be `pending_activation`)
6. **Keep PayID secure** - treat like sensitive payment information
7. **Use environment variables** for sensitive configuration
8. **Test in prelive environment** before using in production
9. **Implement proper logging** for audit trails
10. **Verify virtual account exists** before registering PayID

