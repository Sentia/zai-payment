#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick demo script for User Management
# This script demonstrates basic user operations

require 'bundler/setup'
require 'zai_payment'

# Configure ZaiPayment
puts 'Configuring ZaiPayment...'
ZaiPayment.configure do |config|
  config.environment = :prelive
  config.client_id = ENV['ZAI_CLIENT_ID'] || 'your_client_id'
  config.client_secret = ENV['ZAI_CLIENT_SECRET'] || 'your_client_secret'
  config.scope = ENV['ZAI_SCOPE'] || 'your_scope'
end

puts "✓ Configuration complete\n\n"

# Example 1: Create a Payin User (Buyer)
puts '=' * 60
puts 'Example 1: Creating a Payin User (Buyer)'
puts '=' * 60

begin
  payin_response = ZaiPayment.users.create(
    email: "buyer_#{Time.now.to_i}@example.com",
    first_name: 'John',
    last_name: 'Doe',
    country: 'USA',
    mobile: '+1234567890',
    address_line1: '123 Main St',
    city: 'New York',
    state: 'NY',
    zip: '10001'
  )

  puts '✓ Payin user created successfully!'
  puts "  User ID: #{payin_response.data['id']}"
  puts "  Email: #{payin_response.data['email']}"
  puts "  Name: #{payin_response.data['first_name']} #{payin_response.data['last_name']}"
rescue ZaiPayment::Errors::ApiError => e
  puts "✗ Error creating payin user: #{e.message}"
end

puts "\n"

# Example 2: Create a Payout User (Seller/Merchant)
puts '=' * 60
puts 'Example 2: Creating a Payout User (Seller/Merchant)'
puts '=' * 60

begin
  payout_response = ZaiPayment.users.create(
    email: "seller_#{Time.now.to_i}@example.com",
    first_name: 'Jane',
    last_name: 'Smith',
    country: 'AUS',
    dob: '19900101',
    address_line1: '456 Market St',
    city: 'Sydney',
    state: 'NSW',
    zip: '2000',
    mobile: '+61412345678',
    user_type: 'payout'
  )

  puts '✓ Payout user created successfully!'
  puts "  User ID: #{payout_response.data['id']}"
  puts "  Email: #{payout_response.data['email']}"
  puts "  Name: #{payout_response.data['first_name']} #{payout_response.data['last_name']}"
  puts "  Country: #{payout_response.data['country']}"
rescue ZaiPayment::Errors::ApiError => e
  puts "✗ Error creating payout user: #{e.message}"
end

puts "\n"

# Example 3: List Users
puts '=' * 60
puts 'Example 3: Listing Users'
puts '=' * 60

begin
  list_response = ZaiPayment.users.list(limit: 5, offset: 0)

  puts "✓ Retrieved #{list_response.data.length} users"
  puts "  Total: #{list_response.meta['total']}" if list_response.meta

  list_response.data.each_with_index do |user, index|
    puts "\n  #{index + 1}. #{user['email']}"
    puts "     ID: #{user['id']}"
    puts "     Name: #{user['first_name']} #{user['last_name']}"
  end
rescue ZaiPayment::Errors::ApiError => e
  puts "✗ Error listing users: #{e.message}"
end

puts "\n"

# Example 4: Show User Details
puts '=' * 60
puts 'Example 4: Getting User Details'
puts '=' * 60

if defined?(payin_response) && payin_response&.data&.dig('id')
  user_id = payin_response.data['id']

  begin
    show_response = ZaiPayment.users.show(user_id)

    puts "✓ Retrieved user details for: #{user_id}"
    puts "  Email: #{show_response.data['email']}"
    puts "  Name: #{show_response.data['first_name']} #{show_response.data['last_name']}"
    puts "  Country: #{show_response.data['country']}"
    puts "  City: #{show_response.data['city']}, #{show_response.data['state']}"
  rescue ZaiPayment::Errors::ApiError => e
    puts "✗ Error getting user details: #{e.message}"
  end
else
  puts '⊘ Skipped (no user ID available)'
end

puts "\n"

# Example 5: Update User
puts '=' * 60
puts 'Example 5: Updating User Information'
puts '=' * 60

if defined?(payin_response) && payin_response&.data&.dig('id')
  user_id = payin_response.data['id']

  begin
    update_response = ZaiPayment.users.update(
      user_id,
      mobile: '+9876543210',
      address_line1: '789 Updated Street'
    )

    puts '✓ User updated successfully!'
    puts "  User ID: #{update_response.data['id']}"
    puts "  New Mobile: #{update_response.data['mobile']}"
    puts "  New Address: #{update_response.data['address_line1']}"
  rescue ZaiPayment::Errors::ApiError => e
    puts "✗ Error updating user: #{e.message}"
  end
else
  puts '⊘ Skipped (no user ID available)'
end

puts "\n"

# Example 6: Error Handling
puts '=' * 60
puts 'Example 6: Demonstrating Error Handling'
puts '=' * 60

begin
  # This should fail validation
  ZaiPayment.users.create(
    email: 'invalid-email', # Invalid format
    first_name: 'Test',
    last_name: 'User',
    country: 'US' # Invalid: should be 3 letters
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts '✓ Validation error caught correctly:'
  puts "  Error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts '✓ API error caught:'
  puts "  Error: #{e.message}"
end

puts "\n"
puts '=' * 60
puts 'Demo Complete!'
puts '=' * 60
puts "\nFor more examples, see:"
puts '  - examples/users.md'
puts '  - docs/USERS.md'
puts "\nFor API documentation, visit:"
puts '  - https://developer.hellozai.com/'
