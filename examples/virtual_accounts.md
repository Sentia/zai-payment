# Virtual Account Management Examples

This document provides practical examples for managing virtual accounts in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [List Virtual Accounts Example](#list-virtual-accounts-example)
- [Show Virtual Account Example](#show-virtual-account-example)
- [Create Virtual Account Example](#create-virtual-account-example)
- [Update AKA Names Example](#update-aka-names-example)
- [Update Account Name Example](#update-account-name-example)
- [Update Status Example](#update-status-example)
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

## List Virtual Accounts Example

### Example 1: List All Virtual Accounts

List all virtual accounts for a given wallet account.

```ruby
# List virtual accounts
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')

if response.success?
  accounts = response.data
  
  puts "Found #{accounts.length} virtual account(s)"
  puts "Total: #{response.meta['total']}"
  puts "─" * 60
  
  accounts.each_with_index do |account, index|
    puts "\nVirtual Account ##{index + 1}:"
    puts "  ID: #{account['id']}"
    puts "  Account Name: #{account['account_name']}"
    puts "  BSB: #{account['routing_number']}"
    puts "  Account Number: #{account['account_number']}"
    puts "  Status: #{account['status']}"
    puts "  Currency: #{account['currency']}"
    puts "  Created: #{account['created_at']}"
  end
else
  puts "Failed to retrieve virtual accounts"
  puts "Error: #{response.error}"
end
```

### Example 2: Check if Virtual Accounts Exist

Check if a wallet account has any virtual accounts.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

begin
  response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')
  
  if response.success?
    if response.data.empty?
      puts "No virtual accounts found for this wallet"
      puts "You can create one using the create method"
    else
      puts "Found #{response.data.length} virtual account(s)"
      
      # Check if any are active
      active_accounts = response.data.select { |a| a['status'] == 'active' }
      puts "#{active_accounts.length} active account(s)"
      
      # Check if any are pending
      pending_accounts = response.data.select { |a| a['status'] == 'pending_activation' }
      puts "#{pending_accounts.length} pending activation"
    end
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Wallet account not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 3: Find Active Virtual Accounts

Find and display only active virtual accounts.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')

if response.success?
  active_accounts = response.data.select { |account| account['status'] == 'active' }
  
  if active_accounts.any?
    puts "Active Virtual Accounts:"
    puts "─" * 60
    
    active_accounts.each do |account|
      puts "\n#{account['account_name']}"
      puts "  BSB: #{account['routing_number']} | Account: #{account['account_number']}"
      puts "  ID: #{account['id']}"
      
      if account['aka_names'] && account['aka_names'].any?
        puts "  AKA Names: #{account['aka_names'].join(', ')}"
      end
    end
  else
    puts "No active virtual accounts found"
  end
end
```

### Example 4: Using Convenience Method

Use the convenience method from ZaiPayment module.

```ruby
# Using convenience accessor
response = ZaiPayment.virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')

if response.success?
  puts "Virtual Accounts: #{response.data.length}"
  puts "Total from meta: #{response.meta['total']}"
  
  response.data.each do |account|
    puts "- #{account['account_name']} (#{account['status']})"
  end
end
```

### Example 5: Export Virtual Accounts to CSV

Export virtual account details to CSV format.

```ruby
require 'csv'

virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')

if response.success?
  CSV.open('virtual_accounts.csv', 'w') do |csv|
    # Header
    csv << ['ID', 'Account Name', 'BSB', 'Account Number', 'Status', 'Currency', 'Created At']
    
    # Data rows
    response.data.each do |account|
      csv << [
        account['id'],
        account['account_name'],
        account['routing_number'],
        account['account_number'],
        account['status'],
        account['currency'],
        account['created_at']
      ]
    end
  end
  
  puts "Exported #{response.data.length} virtual accounts to virtual_accounts.csv"
else
  puts "Failed to retrieve virtual accounts"
end
```

## Show Virtual Account Example

### Example 1: Get Virtual Account Details

Retrieve details of a specific virtual account by its ID.

```ruby
# Get virtual account details
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if response.success?
  account = response.data
  
  puts "Virtual Account Details:"
  puts "─" * 60
  puts "ID: #{account['id']}"
  puts "Account Name: #{account['account_name']}"
  puts "Status: #{account['status']}"
  puts ""
  puts "Banking Details:"
  puts "  BSB (Routing Number): #{account['routing_number']}"
  puts "  Account Number: #{account['account_number']}"
  puts "  Currency: #{account['currency']}"
  puts ""
  puts "Account Information:"
  puts "  Account Type: #{account['account_type']}"
  puts "  Full Legal Name: #{account['full_legal_account_name']}"
  puts "  Merchant ID: #{account['merchant_id']}"
  puts ""
  puts "Associated IDs:"
  puts "  Wallet Account ID: #{account['wallet_account_id']}"
  puts "  User External ID: #{account['user_external_id']}"
  puts ""
  puts "AKA Names:"
  account['aka_names'].each do |aka_name|
    puts "  - #{aka_name}"
  end
  puts ""
  puts "Timestamps:"
  puts "  Created: #{account['created_at']}"
  puts "  Updated: #{account['updated_at']}"
  puts "─" * 60
else
  puts "Failed to retrieve virtual account"
  puts "Error: #{response.error}"
end
```

### Example 2: Check Virtual Account Status

Check if a virtual account is active before proceeding with operations.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

begin
  response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
  
  if response.success?
    account = response.data
    
    case account['status']
    when 'active'
      puts "✓ Virtual account is active and ready to receive payments"
      puts "  BSB: #{account['routing_number']}"
      puts "  Account: #{account['account_number']}"
      puts "  Name: #{account['account_name']}"
    when 'pending_activation'
      puts "⏳ Virtual account is pending activation"
      puts "  Please wait for activation to complete"
    when 'inactive'
      puts "✗ Virtual account is inactive"
      puts "  Cannot receive payments at this time"
    else
      puts "⚠ Unknown status: #{account['status']}"
    end
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Virtual account not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 3: Get Payment Instructions

Generate payment instructions for customers based on virtual account details.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if response.success?
  account = response.data
  
  if account['status'] == 'active'
    puts "Payment Instructions for #{account['account_name']}"
    puts "=" * 60
    puts ""
    puts "To make a payment, please transfer funds to:"
    puts ""
    puts "  Account Name: #{account['account_name']}"
    puts "  BSB: #{account['routing_number']}"
    puts "  Account Number: #{account['account_number']}"
    puts ""
    puts "Please use one of the following names when making the transfer:"
    account['aka_names'].each_with_index do |aka_name, index|
      puts "  #{index + 1}. #{aka_name}"
    end
    puts ""
    puts "Currency: #{account['currency']}"
    puts "=" * 60
  else
    puts "This virtual account is not active yet."
    puts "Status: #{account['status']}"
  end
end
```

### Example 4: Using Convenience Method

Use the convenience method from ZaiPayment module.

```ruby
# Using convenience accessor
response = ZaiPayment.virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if response.success?
  account = response.data
  puts "Account: #{account['account_name']}"
  puts "Status: #{account['status']}"
  puts "BSB: #{account['routing_number']} | Account: #{account['account_number']}"
end
```

### Example 5: Validate Virtual Account Before Payment

Validate virtual account details before initiating a payment.

```ruby
def validate_virtual_account(virtual_account_id)
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    response = virtual_accounts.show(virtual_account_id)
    
    if response.success?
      account = response.data
      
      # Validation checks
      errors = []
      errors << "Account is not active" unless account['status'] == 'active'
      errors << "Missing routing number" unless account['routing_number']
      errors << "Missing account number" unless account['account_number']
      errors << "Currency mismatch" unless account['currency'] == 'AUD'
      
      if errors.empty?
        {
          valid: true,
          account: account,
          payment_details: {
            bsb: account['routing_number'],
            account_number: account['account_number'],
            account_name: account['account_name']
          }
        }
      else
        {
          valid: false,
          errors: errors,
          account: account
        }
      end
    else
      {
        valid: false,
        errors: ['Failed to retrieve virtual account']
      }
    end
    
  rescue ZaiPayment::Errors::NotFoundError
    {
      valid: false,
      errors: ['Virtual account not found']
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      valid: false,
      errors: ["API Error: #{e.message}"]
    }
  end
end

# Usage
result = validate_virtual_account('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

if result[:valid]
  puts "✓ Virtual account is valid"
  puts "Payment Details:"
  puts "  BSB: #{result[:payment_details][:bsb]}"
  puts "  Account: #{result[:payment_details][:account_number]}"
  puts "  Name: #{result[:payment_details][:account_name]}"
else
  puts "✗ Virtual account validation failed:"
  result[:errors].each { |error| puts "  - #{error}" }
end
```

### Example 6: Compare Multiple Virtual Accounts

Retrieve and compare multiple virtual accounts.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

account_ids = [
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
]

puts "Virtual Account Comparison"
puts "=" * 80

account_ids.each do |account_id|
  begin
    response = virtual_accounts.show(account_id)
    
    if response.success?
      account = response.data
      puts "\n#{account['account_name']}"
      puts "  ID: #{account_id[0..7]}..."
      puts "  Status: #{account['status']}"
      puts "  BSB: #{account['routing_number']} | Account: #{account['account_number']}"
      puts "  Created: #{Date.parse(account['created_at']).strftime('%Y-%m-%d')}"
    end
  rescue ZaiPayment::Errors::NotFoundError
    puts "\n#{account_id[0..7]}..."
    puts "  Status: Not Found"
  end
end

puts "\n#{'=' * 80}"
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

## Update AKA Names Example

### Example 1: Update AKA Names for a Virtual Account

Replace the list of AKA names for a virtual account.

```ruby
# Update AKA names
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.update_aka_names(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  ['Updated Name 1', 'Updated Name 2', 'Updated Name 3']
)

if response.success?
  account = response.data
  puts "AKA Names Updated Successfully!"
  puts "Virtual Account: #{account['account_name']}"
  puts "New AKA Names:"
  account['aka_names'].each_with_index do |aka_name, index|
    puts "  #{index + 1}. #{aka_name}"
  end
else
  puts "Failed to update AKA names"
  puts "Error: #{response.error}"
end
```

### Example 2: Clear All AKA Names

Remove all AKA names from a virtual account by passing an empty array.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.update_aka_names(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  []
)

if response.success?
  puts "All AKA names cleared successfully"
  puts "Current AKA names: #{response.data['aka_names'].inspect}"
end
```

### Example 3: Set Single AKA Name

Update to have just one AKA name.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.update_aka_names(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  ['Preferred Name']
)

if response.success?
  account = response.data
  puts "✓ AKA names updated to single name"
  puts "  Account: #{account['account_name']}"
  puts "  AKA: #{account['aka_names'].first}"
end
```

### Example 4: Using Convenience Method

Use the convenience method from ZaiPayment module.

```ruby
# Using convenience accessor
response = ZaiPayment.virtual_accounts.update_aka_names(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  ['New Name 1', 'New Name 2']
)

if response.success?
  puts "Updated AKA names: #{response.data['aka_names'].join(', ')}"
end
```

### Example 5: Update After Checking Current Names

Check current AKA names before updating.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
virtual_account_id = '46deb476-c1a6-41eb-8eb7-26a695bbe5bc'

begin
  # First, show current virtual account
  show_response = virtual_accounts.show(virtual_account_id)
  
  if show_response.success?
    current_account = show_response.data
    
    puts "Current AKA names:"
    current_account['aka_names'].each { |name| puts "  - #{name}" }
    
    # Update with new names
    new_aka_names = [
      'Real Estate Agency',
      'RE Agency',
      'Property Management'
    ]
    
    update_response = virtual_accounts.update_aka_names(virtual_account_id, new_aka_names)
    
    if update_response.success?
      puts "\n✓ Successfully updated AKA names"
      puts "New AKA names:"
      update_response.data['aka_names'].each { |name| puts "  - #{name}" }
    end
  end
  
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 6: Bulk Update with Validation

Update AKA names with pre-validation and error handling.

```ruby
def safely_update_aka_names(virtual_account_id, new_aka_names)
  # Pre-validate
  errors = []
  errors << "aka_names must be an array" unless new_aka_names.is_a?(Array)
  errors << "Maximum 3 AKA names allowed" if new_aka_names.length > 3
  errors << "AKA names cannot be empty strings" if new_aka_names.any? { |name| name.to_s.strip.empty? }
  
  if errors.any?
    return {
      success: false,
      errors: errors
    }
  end
  
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    response = virtual_accounts.update_aka_names(virtual_account_id, new_aka_names)
    
    {
      success: true,
      account: response.data,
      aka_names: response.data['aka_names']
    }
  rescue ZaiPayment::Errors::ValidationError => e
    {
      success: false,
      errors: [e.message]
    }
  rescue ZaiPayment::Errors::NotFoundError => e
    {
      success: false,
      errors: ['Virtual account not found']
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      errors: ["API Error: #{e.message}"]
    }
  end
end

# Usage
result = safely_update_aka_names(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  ['Agency A', 'Agency B']
)

if result[:success]
  puts "✓ AKA names updated successfully"
  puts "New names: #{result[:aka_names].join(', ')}"
else
  puts "✗ Update failed:"
  result[:errors].each { |error| puts "  - #{error}" }
end
```

## Update Account Name Example

### Example 1: Update Account Name for a Virtual Account

Change the name of a virtual account.

```ruby
# Update account name
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

response = virtual_accounts.update_account_name(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'New Real Estate Agency Name'
)

if response.success?
  account = response.data
  puts "Account Name Updated Successfully!"
  puts "Virtual Account ID: #{account['id']}"
  puts "New Account Name: #{account['account_name']}"
  puts "Status: #{account['status']}"
else
  puts "Failed to update account name"
  puts "Error: #{response.error}"
end
```

### Example 2: Update After Business Name Change

Update account name after a business rebranding or name change.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

begin
  # Show current account first
  show_response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
  
  if show_response.success?
    old_name = show_response.data['account_name']
    puts "Current account name: #{old_name}"
    
    # Update to new name
    new_name = 'Premium Real Estate Partners'
    update_response = virtual_accounts.update_account_name(
      '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      new_name
    )
    
    if update_response.success?
      puts "✓ Successfully updated account name"
      puts "  From: #{old_name}"
      puts "  To: #{update_response.data['account_name']}"
    end
  end
  
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation Error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 3: Using Convenience Method

Use the convenience method from ZaiPayment module.

```ruby
# Using convenience accessor
response = ZaiPayment.virtual_accounts.update_account_name(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'Updated Property Management Co'
)

if response.success?
  puts "Updated account name: #{response.data['account_name']}"
end
```

### Example 4: Update with Maximum Length Name

Update with a name at the maximum allowed length (140 characters).

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

# Create a name at exactly 140 characters
long_name = 'A' * 140

response = virtual_accounts.update_account_name(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  long_name
)

if response.success?
  account = response.data
  puts "✓ Account name updated"
  puts "  Length: #{account['account_name'].length} characters"
  puts "  Name: #{account['account_name'][0..50]}..." # Show first 50 chars
end
```

### Example 5: Validate Before Updating

Pre-validate the account name before making the API call.

```ruby
def safely_update_account_name(virtual_account_id, new_account_name)
  # Pre-validate
  errors = []
  
  if new_account_name.nil? || new_account_name.strip.empty?
    errors << "Account name cannot be blank"
  elsif new_account_name.length > 140
    errors << "Account name must be 140 characters or less (currently #{new_account_name.length})"
  end
  
  if errors.any?
    return {
      success: false,
      errors: errors
    }
  end
  
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    response = virtual_accounts.update_account_name(virtual_account_id, new_account_name)
    
    {
      success: true,
      account: response.data,
      account_name: response.data['account_name']
    }
  rescue ZaiPayment::Errors::ValidationError => e
    {
      success: false,
      errors: [e.message]
    }
  rescue ZaiPayment::Errors::NotFoundError => e
    {
      success: false,
      errors: ['Virtual account not found']
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      success: false,
      errors: ["API Error: #{e.message}"]
    }
  end
end

# Usage
result = safely_update_account_name(
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'New Business Name'
)

if result[:success]
  puts "✓ Account name updated successfully"
  puts "New name: #{result[:account_name]}"
else
  puts "✗ Update failed:"
  result[:errors].each { |error| puts "  - #{error}" }
end
```

### Example 6: Update Multiple Virtual Accounts

Update account names for multiple virtual accounts in bulk.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

updates = [
  { id: '46deb476-c1a6-41eb-8eb7-26a695bbe5bc', name: 'Property A Trust' },
  { id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', name: 'Property B Trust' }
]

results = updates.map do |update|
  begin
    response = virtual_accounts.update_account_name(update[:id], update[:name])
    
    {
      id: update[:id],
      success: true,
      new_name: response.data['account_name']
    }
  rescue ZaiPayment::Errors::ApiError => e
    {
      id: update[:id],
      success: false,
      error: e.message
    }
  end
end

# Display results
results.each do |result|
  if result[:success]
    puts "✓ #{result[:id][0..7]}... → #{result[:new_name]}"
  else
    puts "✗ #{result[:id][0..7]}... → #{result[:error]}"
  end
end

successes = results.count { |r| r[:success] }
puts "\nUpdated #{successes} out of #{results.length} virtual accounts"
```

## Update Status Example

### Example 1: Close a Virtual Account

Close a virtual account by setting its status to 'closed'. This is an asynchronous operation.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

begin
  response = virtual_accounts.update_status(
    '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
    'closed'
  )
  
  if response.success?
    puts "Virtual account closure initiated"
    puts "ID: #{response.data['id']}"
    puts "Message: #{response.data['message']}"
    puts "Link: #{response.data['links']['self']}"
    puts "\nNote: The status update is being processed asynchronously."
    puts "Use the show method to check the current status."
  end
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Virtual account not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Example 2: Close and Verify Status

Close a virtual account and verify the status change.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
virtual_account_id = '46deb476-c1a6-41eb-8eb7-26a695bbe5bc'

begin
  # Get current status
  current_response = virtual_accounts.show(virtual_account_id)
  current_status = current_response.data['status']
  
  puts "Current status: #{current_status}"
  
  if current_status == 'closed'
    puts "Virtual account is already closed"
  elsif current_status == 'pending_activation'
    puts "Virtual account is still pending activation. Cannot close yet."
  else
    # Close the account
    close_response = virtual_accounts.update_status(virtual_account_id, 'closed')
    
    if close_response.success?
      puts "✓ Closure request submitted successfully"
      puts "Message: #{close_response.data['message']}"
      
      # Wait a moment for processing
      sleep(2)
      
      # Check new status
      updated_response = virtual_accounts.show(virtual_account_id)
      new_status = updated_response.data['status']
      
      puts "\nUpdated status: #{new_status}"
      puts "Status changed: #{current_status} → #{new_status}"
    end
  end
  
rescue ZaiPayment::Errors::ApiError => e
  puts "Error: #{e.message}"
end
```

### Example 3: Close Multiple Virtual Accounts

Close multiple virtual accounts in batch.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new

account_ids_to_close = [
  '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  'cccccccc-dddd-eeee-ffff-000000000000'
]

results = []

puts "Closing #{account_ids_to_close.length} virtual accounts..."
puts "─" * 60

account_ids_to_close.each_with_index do |account_id, index|
  begin
    response = virtual_accounts.update_status(account_id, 'closed')
    
    if response.success?
      results << {
        id: account_id,
        success: true,
        message: response.data['message']
      }
      puts "✓ Account #{index + 1}: #{account_id[0..7]}... - Closure initiated"
    end
    
  rescue ZaiPayment::Errors::NotFoundError => e
    results << { id: account_id, success: false, error: 'Not found' }
    puts "✗ Account #{index + 1}: #{account_id[0..7]}... - Not found"
  rescue ZaiPayment::Errors::ApiError => e
    results << { id: account_id, success: false, error: e.message }
    puts "✗ Account #{index + 1}: #{account_id[0..7]}... - #{e.message}"
  end
end

puts "─" * 60
successes = results.count { |r| r[:success] }
failures = results.count { |r| !r[:success] }

puts "\nResults:"
puts "  Successful closures: #{successes}"
puts "  Failed closures: #{failures}"
```

### Example 4: Safe Close with Confirmation

Close a virtual account with additional safety checks.

```ruby
def close_virtual_account_safely(virtual_account_id)
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    # First, retrieve the account details
    account_response = virtual_accounts.show(virtual_account_id)
    account = account_response.data
    
    puts "Virtual Account Details:"
    puts "  ID: #{account['id']}"
    puts "  Account Name: #{account['account_name']}"
    puts "  BSB: #{account['routing_number']}"
    puts "  Account Number: #{account['account_number']}"
    puts "  Current Status: #{account['status']}"
    puts "  Created: #{account['created_at']}"
    
    # Check if already closed
    if account['status'] == 'closed'
      puts "\n⚠ Account is already closed."
      return { success: false, reason: 'already_closed' }
    end
    
    # Check if pending activation
    if account['status'] == 'pending_activation'
      puts "\n⚠ Account is still pending activation."
      puts "Consider waiting for activation before closing."
      return { success: false, reason: 'pending_activation' }
    end
    
    # Proceed with closing
    puts "\nProceeding to close account..."
    close_response = virtual_accounts.update_status(virtual_account_id, 'closed')
    
    if close_response.success?
      puts "✓ Account closure initiated successfully"
      puts "Message: #{close_response.data['message']}"
      
      return {
        success: true,
        id: close_response.data['id'],
        message: close_response.data['message']
      }
    end
    
  rescue ZaiPayment::Errors::NotFoundError => e
    puts "✗ Virtual account not found: #{virtual_account_id}"
    return { success: false, reason: 'not_found', error: e.message }
  rescue ZaiPayment::Errors::ValidationError => e
    puts "✗ Validation error: #{e.message}"
    return { success: false, reason: 'validation_error', error: e.message }
  rescue ZaiPayment::Errors::ApiError => e
    puts "✗ API Error: #{e.message}"
    return { success: false, reason: 'api_error', error: e.message }
  end
end

# Usage
result = close_virtual_account_safely('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
puts "\nFinal result: #{result.inspect}"
```

### Example 5: Close with Status Polling

Close an account and poll for status confirmation.

```ruby
def close_and_wait_for_confirmation(virtual_account_id, max_attempts = 10, wait_seconds = 3)
  virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
  
  begin
    # Initiate closure
    puts "Initiating closure for virtual account #{virtual_account_id[0..7]}..."
    close_response = virtual_accounts.update_status(virtual_account_id, 'closed')
    
    unless close_response.success?
      puts "✗ Failed to initiate closure"
      return { success: false, reason: 'closure_failed' }
    end
    
    puts "✓ Closure request accepted"
    puts "Message: #{close_response.data['message']}"
    puts "\nPolling for status confirmation..."
    
    # Poll for status
    max_attempts.times do |attempt|
      sleep(wait_seconds)
      
      show_response = virtual_accounts.show(virtual_account_id)
      current_status = show_response.data['status']
      
      puts "  Attempt #{attempt + 1}/#{max_attempts}: Status = #{current_status}"
      
      if current_status == 'closed'
        puts "\n✓ Account successfully closed!"
        return {
          success: true,
          status: current_status,
          attempts: attempt + 1,
          elapsed_time: (attempt + 1) * wait_seconds
        }
      end
    end
    
    puts "\n⚠ Timeout: Status not confirmed as 'closed' after #{max_attempts} attempts"
    puts "The account may still be processing. Check again later."
    
    return {
      success: false,
      reason: 'timeout',
      max_attempts: max_attempts,
      elapsed_time: max_attempts * wait_seconds
    }
    
  rescue ZaiPayment::Errors::ApiError => e
    puts "✗ Error: #{e.message}"
    return { success: false, reason: 'api_error', error: e.message }
  end
end

# Usage
result = close_and_wait_for_confirmation('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
puts "\nResult: #{result.inspect}"
```

### Example 6: Validate Status Before Closing

Ensure only valid status transitions.

```ruby
virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
virtual_account_id = '46deb476-c1a6-41eb-8eb7-26a695bbe5bc'

# Note: Only 'closed' is a valid status value for the update_status method
valid_status = 'closed'

begin
  # Attempt to use an invalid status (for demonstration)
  invalid_status = 'active'
  
  begin
    virtual_accounts.update_status(virtual_account_id, invalid_status)
  rescue ZaiPayment::Errors::ValidationError => e
    puts "Expected validation error for invalid status:"
    puts "  Error: #{e.message}"
    puts "  Only 'closed' is allowed as a status value"
  end
  
  # Now use the correct status
  puts "\nUsing valid status: '#{valid_status}'"
  response = virtual_accounts.update_status(virtual_account_id, valid_status)
  
  if response.success?
    puts "✓ Status update successful"
    puts "Message: #{response.data['message']}"
  end
  
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

