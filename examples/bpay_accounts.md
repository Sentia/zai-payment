# BPay Account Management Examples

This document provides practical examples for managing BPay accounts in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Show BPay Account Example](#show-bpay-account-example)
- [Show BPay Account User Example](#show-bpay-account-user-example)
- [Redact BPay Account Example](#redact-bpay-account-example)
- [Create BPay Account Example](#create-bpay-account-example)
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

## Show BPay Account Example

### Example 1: Get BPay Account Details

Retrieve details of a specific BPay account.

```ruby
# Get BPay account details
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

response = bpay_accounts.show('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

if response.success?
  bpay_account = response.data
  puts "BPay Account ID: #{bpay_account['id']}"
  puts "Active: #{bpay_account['active']}"
  puts "Verification Status: #{bpay_account['verification_status']}"
  puts "Currency: #{bpay_account['currency']}"
  puts "Created At: #{bpay_account['created_at']}"
  puts "Updated At: #{bpay_account['updated_at']}"
  
  # Access BPay details
  bpay_details = bpay_account['bpay_details']
  puts "\nBPay Details:"
  puts "  Account Name: #{bpay_details['account_name']}"
  puts "  Biller Code: #{bpay_details['biller_code']}"
  puts "  Biller Name: #{bpay_details['biller_name']}"
  puts "  CRN: #{bpay_details['crn']}"
  
  # Access links
  links = bpay_account['links']
  puts "\nLinks:"
  puts "  Self: #{links['self']}"
  puts "  Users: #{links['users']}"
else
  puts "Failed to retrieve BPay account"
  puts "Error: #{response.error}"
end
```

### Example 2: Show BPay Account with Error Handling

Handle edge cases when retrieving BPay account details.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

begin
  response = bpay_accounts.show('bpay_account_id_here')
  
  if response.success?
    bpay_account = response.data
    
    # Check if account is active
    if bpay_account['active']
      puts "BPay account is active"
      puts "Biller: #{bpay_account['bpay_details']['biller_name']}"
      puts "CRN: #{bpay_account['bpay_details']['crn']}"
    else
      puts "BPay account is inactive"
    end
    
    # Check verification status
    case bpay_account['verification_status']
    when 'verified'
      puts "Account is verified and ready to use"
    when 'not_verified'
      puts "Account pending verification"
    when 'pending_verification'
      puts "Account verification in progress"
    end
  else
    puts "Failed to retrieve BPay account: #{response.error}"
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "BPay account not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid BPay account ID: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error occurred: #{e.message}"
end
```

### Example 3: Verify BPay Account Details Before Processing

Check BPay account details before initiating a disbursement.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Step 1: Retrieve BPay account
response = bpay_accounts.show('bpay_account_id')

if response.success?
  bpay_account = response.data
  
  # Step 2: Verify account is ready for disbursement
  if bpay_account['active'] && bpay_account['verification_status'] == 'verified'
    bpay_details = bpay_account['bpay_details']
    
    puts "Ready to disburse to:"
    puts "  Biller: #{bpay_details['biller_name']}"
    puts "  Account: #{bpay_details['account_name']}"
    puts "  CRN: #{bpay_details['crn']}"
    
    # Proceed with disbursement
    # items.make_payment(...)
  else
    puts "Cannot disburse: Account not ready"
    puts "  Active: #{bpay_account['active']}"
    puts "  Status: #{bpay_account['verification_status']}"
  end
end
```

## Show BPay Account User Example

### Example 1: Get User Associated with BPay Account

Retrieve user details for a BPay account.

```ruby
# Get user associated with BPay account
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

response = bpay_accounts.show_user('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

if response.success?
  user = response.data
  puts "User ID: #{user['id']}"
  puts "Full Name: #{user['full_name']}"
  puts "Email: #{user['email']}"
  puts "First Name: #{user['first_name']}"
  puts "Last Name: #{user['last_name']}"
  puts "Location: #{user['location']}"
  puts "Verification State: #{user['verification_state']}"
  puts "Held State: #{user['held_state']}"
  puts "Roles: #{user['roles'].join(', ')}"
  
  # Access links
  links = user['links']
  puts "\nLinks:"
  puts "  Self: #{links['self']}"
  puts "  Items: #{links['items']}"
  puts "  Wallet Accounts: #{links['wallet_accounts']}"
else
  puts "Failed to retrieve user"
  puts "Error: #{response.error}"
end
```

### Example 2: Verify User Before Disbursement

Check user details before processing a disbursement to a BPay account.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

begin
  # Step 1: Get user associated with BPay account
  user_response = bpay_accounts.show_user('bpay_account_id')
  
  if user_response.success?
    user = user_response.data
    
    # Step 2: Verify user details
    if user['verification_state'] == 'verified' && !user['held_state']
      puts "User verified and not on hold"
      puts "Name: #{user['full_name']}"
      puts "Email: #{user['email']}"
      
      # Proceed with disbursement
      puts "✓ Ready to process disbursement"
    else
      puts "Cannot disburse:"
      puts "  Verification: #{user['verification_state']}"
      puts "  On Hold: #{user['held_state']}"
    end
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "BPay account not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Example 3: Get User Contact Information

Retrieve user contact details for notifications.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

response = bpay_accounts.show_user('bpay_account_id')

if response.success?
  user = response.data
  
  # Extract contact information
  contact_info = {
    name: user['full_name'],
    email: user['email'],
    mobile: user['mobile'],
    location: user['location']
  }
  
  puts "Contact Information:"
  puts "  Name: #{contact_info[:name]}"
  puts "  Email: #{contact_info[:email]}"
  puts "  Mobile: #{contact_info[:mobile]}"
  puts "  Location: #{contact_info[:location]}"
  
  # Send notification
  # NotificationService.send_disbursement_notice(contact_info)
end
```

## Redact BPay Account Example

### Example 1: Redact a BPay Account

Redact (deactivate) a BPay account so it can no longer be used.

```ruby
# Redact a BPay account
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

response = bpay_accounts.redact('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

if response.success?
  puts "BPay account successfully redacted"
  puts "Response: #{response.data}"
  # => {"bpay_account"=>"Successfully redacted"}
  
  # The BPay account can no longer be used for:
  # - Disbursement destination
else
  puts "Failed to redact BPay account"
  puts "Error: #{response.error}"
end
```

### Example 2: Redact with Error Handling

Handle edge cases when redacting a BPay account.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

begin
  # Attempt to redact the BPay account
  response = bpay_accounts.redact('bpay_account_id_here')
  
  if response.success?
    puts "BPay account redacted successfully"
    
    # Log the action for audit purposes
    Rails.logger.info("BPay account #{bpay_account_id} was redacted at #{Time.now}")
  else
    puts "Redaction failed: #{response.error}"
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "BPay account not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid BPay account ID: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error occurred: #{e.message}"
end
```

### Example 3: Verify Before Redacting

Verify BPay account details before redacting.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Step 1: Retrieve BPay account to verify
response = bpay_accounts.show('bpay_account_id')

if response.success?
  bpay_account = response.data
  
  # Step 2: Confirm details before redacting
  puts "About to redact:"
  puts "  Account: #{bpay_account['bpay_details']['account_name']}"
  puts "  Biller: #{bpay_account['bpay_details']['biller_name']}"
  puts "  Active: #{bpay_account['active']}"
  
  # Step 3: Redact the account
  redact_response = bpay_accounts.redact('bpay_account_id')
  
  if redact_response.success?
    puts "\n✓ BPay account redacted successfully"
  else
    puts "\n✗ Failed to redact BPay account"
  end
end
```

## Create BPay Account Example

### Example 1: Create Basic BPay Account

Create a BPay account for disbursement destination.

```ruby
# Create a BPay account
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
  puts "\nBPay Details:"
  puts "  Account Name: #{bpay_details['account_name']}"
  puts "  Biller Code: #{bpay_details['biller_code']}"
  puts "  Biller Name: #{bpay_details['biller_name']}"
  puts "  CRN: #{bpay_details['crn']}"
  
  # Access links
  links = bpay_account['links']
  puts "\nLinks:"
  puts "  Self: #{links['self']}"
  puts "  Users: #{links['users']}"
else
  puts "Failed to create BPay account"
  puts "Error: #{response.error}"
end
```

### Example 2: Create BPay Account with Error Handling

Handle validation errors when creating BPay accounts.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

begin
  response = bpay_accounts.create(
    user_id: 'user_123',
    account_name: 'My Electricity Bill',
    biller_code: 456789,
    bpay_crn: '123456789'
  )
  
  if response.success?
    puts "BPay account created successfully!"
    puts "Account ID: #{response.data['id']}"
  else
    puts "Failed to create BPay account: #{response.error}"
  end
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
  puts "Status code: #{e.status_code}"
end
```

### Example 3: Create BPay Account for Utility Payment

Create a BPay account for utility bill payments.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Water bill
response = bpay_accounts.create(
  user_id: 'user_456',
  account_name: 'Sydney Water Bill',
  biller_code: 12345,
  bpay_crn: '1122334455'
)

if response.success?
  puts "Water bill BPay account created: #{response.data['id']}"
end

# Electricity bill
response = bpay_accounts.create(
  user_id: 'user_456',
  account_name: 'Energy Australia Bill',
  biller_code: 67890,
  bpay_crn: '9988776655'
)

if response.success?
  puts "Electricity BPay account created: #{response.data['id']}"
end
```

## Common Patterns

### Pattern 1: Retrieve and Verify BPay Account Before Disbursement

Check BPay account status before processing a payment.

```ruby
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

# Step 1: Retrieve BPay account
response = bpay_accounts.show('bpay_account_id')

if response.success?
  bpay_account = response.data
  
  # Step 2: Verify account is ready
  if bpay_account['active'] && bpay_account['verification_status'] == 'verified'
    puts "BPay account is ready for disbursement"
    
    # Step 3: Proceed with payment
    items = ZaiPayment::Resources::Item.new
    payment_response = items.make_payment(
      item_id: 'item_123',
      account_id: bpay_account['id']
    )
    
    puts "Payment initiated" if payment_response.success?
  else
    puts "Account not ready: #{bpay_account['verification_status']}"
  end
end
```

### Pattern 2: Creating BPay Account After User Registration

Typical workflow when setting up disbursement accounts.

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

# Step 2: Create BPay account for the seller
bpay_accounts = ZaiPayment::Resources::BpayAccount.new

bpay_response = bpay_accounts.create(
  user_id: user_id,
  account_name: 'My Service Bill',
  biller_code: 123456,
  bpay_crn: '987654321'
)

if bpay_response.success?
  bpay_account_id = bpay_response.data['id']
  puts "BPay account created: #{bpay_account_id}"
  
  # Step 3: Set as disbursement account
  users.set_disbursement_account(user_id, bpay_account_id)
  puts "Disbursement account set successfully"
end
```

### Pattern 2: BPay Account Form Handler

Implement BPay account creation in a Rails controller.

```ruby
# In a Rails controller
class BpayAccountsController < ApplicationController
  def create
    bpay_accounts = ZaiPayment::Resources::BpayAccount.new
    
    begin
      response = bpay_accounts.create(
        user_id: params[:user_id],
        account_name: params[:account_name],
        biller_code: params[:biller_code].to_i,
        bpay_crn: params[:bpay_crn]
      )
      
      if response.success?
        bpay_account = response.data
        
        render json: {
          success: true,
          bpay_account_id: bpay_account['id'],
          message: 'BPay account created successfully'
        }, status: :created
      else
        render json: {
          success: false,
          message: response.error
        }, status: :unprocessable_entity
      end
    rescue ZaiPayment::Errors::ValidationError => e
      render json: {
        success: false,
        message: e.message
      }, status: :bad_request
    rescue ZaiPayment::Errors::ApiError => e
      render json: {
        success: false,
        message: 'An error occurred while creating the BPay account'
      }, status: :internal_server_error
    end
  end
end
```

### Pattern 3: Validate BPay Details Before Creating Account

Validate biller code and CRN format before API call.

```ruby
class BpayAccountValidator
  def self.validate_biller_code(biller_code)
    biller_code_str = biller_code.to_s
    
    unless biller_code_str.match?(/\A\d{3,10}\z/)
      return { valid: false, message: 'Biller code must be 3 to 10 digits' }
    end
    
    { valid: true }
  end
  
  def self.validate_bpay_crn(bpay_crn)
    bpay_crn_str = bpay_crn.to_s
    
    unless bpay_crn_str.match?(/\A\d{2,20}\z/)
      return { valid: false, message: 'CRN must be between 2 and 20 digits' }
    end
    
    { valid: true }
  end
  
  def self.validate_all(biller_code, bpay_crn)
    biller_validation = validate_biller_code(biller_code)
    return biller_validation unless biller_validation[:valid]
    
    crn_validation = validate_bpay_crn(bpay_crn)
    return crn_validation unless crn_validation[:valid]
    
    { valid: true }
  end
end

# Usage
validation = BpayAccountValidator.validate_all(123456, '987654321')

if validation[:valid]
  bpay_accounts = ZaiPayment::Resources::BpayAccount.new
  response = bpay_accounts.create(
    user_id: 'user_123',
    account_name: 'My Bill',
    biller_code: 123456,
    bpay_crn: '987654321'
  )
  
  puts "BPay account created: #{response.data['id']}" if response.success?
else
  puts "Validation failed: #{validation[:message]}"
end
```

## Important Notes

1. **Required Fields**:
   - `user_id` - The user ID associated with the BPay account
   - `account_name` - Nickname for the BPay account
   - `biller_code` - 3 to 10 digits
   - `bpay_crn` - Customer Reference Number, 2 to 20 digits

2. **Biller Code Validation**:
   - Must be numeric
   - Must be between 3 and 10 digits
   - Example: 123456

3. **BPay CRN Validation**:
   - Must be numeric
   - Must be between 2 and 20 digits
   - Example: 987654321

4. **BPay Account Usage**:
   - Used as a disbursement destination
   - Store the returned `:id` for future use
   - Can be set as default disbursement account

5. **Currency**:
   - BPay accounts are typically in AUD (Australian Dollars)
   - Currency is set automatically based on the marketplace configuration

6. **Verification Status**:
   - New BPay accounts typically have `verification_status: "not_verified"`
   - Verification is handled by Zai

