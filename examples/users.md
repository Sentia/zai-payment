# User Management Examples

This document provides practical examples for managing users in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Payin User Examples](#payin-user-examples)
- [Payout User Examples](#payout-user-examples)
- [Advanced Usage](#advanced-usage)

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

## Payin User Examples

### Example 1: Basic Payin User (Buyer)

Create a buyer with minimal required information.

```ruby
# Create a basic payin user
response = ZaiPayment.users.create(
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)

if response.success?
  user = response.data
  puts "Payin user created successfully!"
  puts "User ID: #{user['id']}"
  puts "Email: #{user['email']}"
else
  puts "Failed to create user"
end
```

### Example 2: Payin User with Complete Profile

Create a buyer with all recommended information for better fraud prevention.

```ruby
response = ZaiPayment.users.create(
  # Required fields
  email: 'john.buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA',
  
  # Recommended fields
  address_line1: '123 Main Street',
  address_line2: 'Apt 4B',
  city: 'New York',
  state: 'NY',
  zip: '10001',
  mobile: '+1234567890',
  dob: '19900115',
  
  # For fraud prevention (required when charging)
  device_id: 'device_abc123xyz',
  ip_address: '192.168.1.1'
)

user = response.data
puts "Complete payin user profile created: #{user['id']}"
```

### Example 3: Progressive Profile Building

Create a user quickly, then update with additional information later.

```ruby
# Step 1: Quick user creation during signup
response = ZaiPayment.users.create(
  email: 'quicksignup@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS'
)

user_id = response.data['id']
puts "User created quickly: #{user_id}"

# Step 2: Update with shipping address during checkout
ZaiPayment.users.update(
  user_id,
  address_line1: '456 Collins Street',
  city: 'Melbourne',
  state: 'VIC',
  zip: '3000',
  mobile: '+61412345678'
)

puts "User profile updated with shipping address"

# Step 3: Add device info before payment
ZaiPayment.users.update(
  user_id,
  device_id: 'device_xyz789',
  ip_address: '203.0.113.42'
)

puts "Device information added for payment"
```

## Payout User Examples

### Example 4: Individual Payout User (Seller)

Create a seller who will receive payments. All required fields must be provided.

```ruby
response = ZaiPayment.users.create(
  # Required for payout users
  email: 'seller@example.com',
  first_name: 'Alice',
  last_name: 'Johnson',
  country: 'USA',
  dob: '19850320',
  address_line1: '789 Market Street',
  city: 'San Francisco',
  state: 'CA',
  zip: '94103',
  
  # Recommended
  mobile: '+14155551234',
  government_number: '123456789',  # SSN or Tax ID
  user_type: 'payout'
)

seller = response.data
puts "Payout user created: #{seller['id']}"
puts "Verification state: #{seller['verification_state']}"
```

### Example 5: Australian Payout User

Create an Australian seller with appropriate details.

```ruby
response = ZaiPayment.users.create(
  email: 'aussie.seller@example.com',
  first_name: 'Bruce',
  last_name: 'Williams',
  country: 'AUS',
  dob: '19800710',
  
  # Australian address
  address_line1: '123 George Street',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000',
  
  mobile: '+61298765432',
  government_number: '123456789',  # TFN (Tax File Number)
  user_type: 'payout'
)

if response.success?
  seller = response.data
  puts "Australian seller created: #{seller['id']}"
  puts "Ready for bank account setup"
end
```

### Example 6: UK Payout User

Create a UK-based seller.

```ruby
response = ZaiPayment.users.create(
  email: 'uk.merchant@example.com',
  first_name: 'Oliver',
  last_name: 'Brown',
  country: 'GBR',  # ISO 3166-1 alpha-3 code for United Kingdom
  dob: '19920505',
  
  # UK address
  address_line1: '10 Downing Street',
  city: 'London',
  state: 'England',
  zip: 'SW1A 2AA',
  
  mobile: '+447700900123',
  government_number: 'AB123456C',  # National Insurance Number
  user_type: 'payout'
)

merchant = response.data
puts "UK merchant created: #{merchant['id']}"
```

## Advanced Usage

### Example 7: List and Search Users

Retrieve and paginate through your users.

```ruby
# Get first page of users
page1 = ZaiPayment.users.list(limit: 10, offset: 0)

puts "Total users: #{page1.meta['total']}"
puts "Showing: #{page1.data.length} users"

page1.data.each_with_index do |user, index|
  puts "#{index + 1}. #{user['email']} - #{user['first_name']} #{user['last_name']}"
end

# Get next page
page2 = ZaiPayment.users.list(limit: 10, offset: 10)
puts "\nNext page has #{page2.data.length} users"
```

### Example 8: Get User Details

Retrieve complete details for a specific user.

```ruby
user_id = 'user_abc123'

response = ZaiPayment.users.show(user_id)

if response.success?
  user = response.data
  
  puts "User Details:"
  puts "  ID: #{user['id']}"
  puts "  Email: #{user['email']}"
  puts "  Name: #{user['first_name']} #{user['last_name']}"
  puts "  Country: #{user['country']}"
  puts "  City: #{user['city']}, #{user['state']}"
  puts "  Created: #{user['created_at']}"
  puts "  Verification: #{user['verification_state']}"
end
```

### Example 9: Update Multiple Fields

Update several user fields at once.

```ruby
user_id = 'user_abc123'

response = ZaiPayment.users.update(
  user_id,
  email: 'newemail@example.com',
  mobile: '+1555123456',
  address_line1: '999 Updated Street',
  city: 'Boston',
  state: 'MA',
  zip: '02101'
)

updated_user = response.data
puts "User #{user_id} updated successfully"
puts "New email: #{updated_user['email']}"
```

### Example 10: Error Handling

Properly handle validation and API errors.

```ruby
begin
  response = ZaiPayment.users.create(
    email: 'invalid-email',  # Invalid format
    first_name: 'Test',
    last_name: 'User',
    country: 'US'  # Invalid: should be 3 letters
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation failed: #{e.message}"
  # Handle validation errors (e.g., show to user)
  
rescue ZaiPayment::Errors::UnauthorizedError => e
  puts "Authentication failed: #{e.message}"
  # Refresh token and retry
  ZaiPayment.refresh_token!
  retry
  
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Resource not found: #{e.message}"
  
rescue ZaiPayment::Errors::ApiError => e
  puts "API error occurred: #{e.message}"
  # Log error for debugging
  
rescue ZaiPayment::Errors::ConnectionError => e
  puts "Connection failed: #{e.message}"
  # Retry with exponential backoff
  
rescue ZaiPayment::Errors::TimeoutError => e
  puts "Request timed out: #{e.message}"
  # Retry request
end
```

### Example 11: Batch User Creation

Create multiple users efficiently.

```ruby
users_to_create = [
  {
    email: 'buyer1@example.com',
    first_name: 'Alice',
    last_name: 'Anderson',
    country: 'USA'
  },
  {
    email: 'buyer2@example.com',
    first_name: 'Bob',
    last_name: 'Brown',
    country: 'USA'
  },
  {
    email: 'seller1@example.com',
    first_name: 'Charlie',
    last_name: 'Chen',
    country: 'AUS',
    dob: '19900101',
    address_line1: '123 Test St',
    city: 'Sydney',
    state: 'NSW',
    zip: '2000',
    user_type: 'payout'
  }
]

created_users = []
failed_users = []

users_to_create.each do |user_data|
  begin
    response = ZaiPayment.users.create(**user_data)
    created_users << response.data
    puts "✓ Created: #{user_data[:email]}"
  rescue ZaiPayment::Errors::ApiError => e
    failed_users << { user: user_data, error: e.message }
    puts "✗ Failed: #{user_data[:email]} - #{e.message}"
  end
end

puts "\nSummary:"
puts "Created: #{created_users.length} users"
puts "Failed: #{failed_users.length} users"
```

### Example 12: User Profile Validator

Create a helper to validate user data before API call.

```ruby
class UserValidator
  def self.validate_payin(attributes)
    errors = []
    
    errors << "Email is required" unless attributes[:email]
    errors << "First name is required" unless attributes[:first_name]
    errors << "Last name is required" unless attributes[:last_name]
    errors << "Country is required" unless attributes[:country]
    
    if attributes[:email] && !valid_email?(attributes[:email])
      errors << "Email format is invalid"
    end
    
    if attributes[:country] && attributes[:country].length != 3
      errors << "Country must be 3-letter ISO code"
    end
    
    if attributes[:dob] && !valid_dob?(attributes[:dob])
      errors << "DOB must be in YYYYMMDD format"
    end
    
    errors
  end
  
  def self.validate_payout(attributes)
    errors = validate_payin(attributes)
    
    # Additional required fields for payout users
    errors << "Address is required for payout users" unless attributes[:address_line1]
    errors << "City is required for payout users" unless attributes[:city]
    errors << "State is required for payout users" unless attributes[:state]
    errors << "Zip is required for payout users" unless attributes[:zip]
    errors << "DOB is required for payout users" unless attributes[:dob]
    
    errors
  end
  
  private
  
  def self.valid_email?(email)
    email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
  end
  
  def self.valid_dob?(dob)
    dob.to_s.match?(/\A\d{8}\z/)
  end
end

# Usage
user_data = {
  email: 'test@example.com',
  first_name: 'Test',
  last_name: 'User',
  country: 'USA'
}

errors = UserValidator.validate_payin(user_data)

if errors.empty?
  response = ZaiPayment.users.create(**user_data)
  puts "User created: #{response.data['id']}"
else
  puts "Validation errors:"
  errors.each { |error| puts "  - #{error}" }
end
```

### Example 13: Rails Integration

Example of integrating with a Rails application.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  after_create :create_zai_user
  
  def create_zai_user
    return if zai_user_id.present?
    
    response = ZaiPayment.users.create(
      email: email,
      first_name: first_name,
      last_name: last_name,
      country: country_code,
      user_type: user_type
    )
    
    update(zai_user_id: response.data['id'])
  rescue ZaiPayment::Errors::ApiError => e
    Rails.logger.error "Failed to create Zai user: #{e.message}"
    # Handle error appropriately
  end
  
  def sync_to_zai
    return unless zai_user_id
    
    ZaiPayment.users.update(
      zai_user_id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      mobile: phone_number,
      address_line1: address,
      city: city,
      state: state,
      zip: zip_code
    )
  end
  
  def fetch_from_zai
    return unless zai_user_id
    
    response = ZaiPayment.users.show(zai_user_id)
    response.data
  end
end

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      # Zai user is created automatically via after_create callback
      redirect_to @user, notice: 'User created successfully'
    else
      render :new
    end
  end
  
  def sync_zai_profile
    @user = User.find(params[:id])
    @user.sync_to_zai
    redirect_to @user, notice: 'Profile synced with Zai'
  rescue ZaiPayment::Errors::ApiError => e
    redirect_to @user, alert: "Sync failed: #{e.message}"
  end
  
  private
  
  def user_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :country_code, :user_type
    )
  end
end
```

## Testing Examples

### Example 14: RSpec Integration Tests

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#create_zai_user' do
    let(:user) { build(:user, email: 'test@example.com') }
    
    before do
      stub_request(:post, %r{/users})
        .to_return(
          status: 201,
          body: { id: 'zai_user_123', email: 'test@example.com' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end
    
    it 'creates a Zai user after user creation' do
      expect { user.save }.to change { user.zai_user_id }.from(nil).to('zai_user_123')
    end
  end
end
```

## Common Patterns

### Pattern 1: Two-Step User Creation

```ruby
# Step 1: Create user during signup (minimal info)
def create_initial_user(email:, name_parts:)
  ZaiPayment.users.create(
    email: email,
    first_name: name_parts[:first],
    last_name: name_parts[:last],
    country: 'USA'  # Default or from IP geolocation
  )
end

# Step 2: Complete profile later
def complete_user_profile(user_id:, profile_data:)
  ZaiPayment.users.update(user_id, **profile_data)
end
```

### Pattern 2: Smart Retry Logic

```ruby
def create_user_with_retry(attributes, max_retries: 3)
  retries = 0
  
  begin
    ZaiPayment.users.create(**attributes)
  rescue ZaiPayment::Errors::TimeoutError, ZaiPayment::Errors::ConnectionError => e
    retries += 1
    if retries < max_retries
      sleep(2 ** retries)  # Exponential backoff
      retry
    else
      raise e
    end
  rescue ZaiPayment::Errors::UnauthorizedError
    ZaiPayment.refresh_token!
    retry
  end
end
```

## See Also

- [User Management Documentation](../docs/USERS.md)
- [Webhook Examples](webhooks.md)
- [Zai API Reference](https://developer.hellozai.com/reference)

