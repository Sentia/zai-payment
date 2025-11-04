# Wallet Account Management Examples

This document provides practical examples for managing wallet accounts in Zai Payment.

## Table of Contents

- [Setup](#setup)
- [Show Wallet Account Example](#show-wallet-account-example)
- [Show Wallet Account User Example](#show-wallet-account-user-example)
- [Pay a Bill Example](#pay-a-bill-example)
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

## Show Wallet Account Example

### Example 1: Get Wallet Account Details

Retrieve details of a specific wallet account.

```ruby
# Get wallet account details
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

response = wallet_accounts.show('5c1c6b10-4c56-0137-8cd7-0242ac110002')

if response.success?
  wallet = response.data
  puts "Wallet Account ID: #{wallet['id']}"
  puts "Active: #{wallet['active']}"
  puts "Balance: $#{wallet['balance'] / 100.0}"
  puts "Currency: #{wallet['currency']}"
  puts "Created At: #{wallet['created_at']}"
  puts "Updated At: #{wallet['updated_at']}"
  
  # Access links
  links = wallet['links']
  puts "\nLinks:"
  puts "  Self: #{links['self']}"
  puts "  Users: #{links['users']}"
  puts "  Transactions: #{links['transactions']}"
  puts "  BPay Details: #{links['bpay_details']}"
  puts "  NPP Details: #{links['npp_details']}"
else
  puts "Failed to retrieve wallet account"
  puts "Error: #{response.error}"
end
```

### Example 2: Check Balance Before Payment

Check wallet balance before initiating a payment.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

begin
  response = wallet_accounts.show('wallet_account_id_here')
  
  if response.success?
    wallet = response.data
    balance = wallet['balance']  # in cents
    
    # Check if account is active
    if wallet['active']
      puts "Wallet is active"
      puts "Current balance: $#{balance / 100.0}"
      
      # Check if sufficient funds for payment
      payment_amount = 17300  # $173.00
      
      if balance >= payment_amount
        puts "Sufficient funds for payment of $#{payment_amount / 100.0}"
      else
        puts "Insufficient funds"
        puts "  Required: $#{payment_amount / 100.0}"
        puts "  Available: $#{balance / 100.0}"
        puts "  Shortfall: $#{(payment_amount - balance) / 100.0}"
      end
    else
      puts "Wallet account is inactive"
    end
  else
    puts "Failed to retrieve wallet account: #{response.error}"
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Wallet account not found: #{e.message}"
rescue ZaiPayment::Errors::ValidationError => e
  puts "Invalid wallet account ID: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error occurred: #{e.message}"
end
```

### Example 3: Monitor Wallet Account Status

Check wallet account status and available resources.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Step 1: Retrieve wallet account
response = wallet_accounts.show('wallet_account_id')

if response.success?
  wallet = response.data
  
  # Step 2: Display wallet status
  puts "Wallet Account Status:"
  puts "  ID: #{wallet['id']}"
  puts "  Active: #{wallet['active']}"
  puts "  Balance: $#{wallet['balance'] / 100.0}"
  puts "  Currency: #{wallet['currency']}"
  
  # Step 3: Check available resources
  links = wallet['links']
  
  puts "\nAvailable Resources:"
  puts "  ✓ Users" if links['users']
  puts "  ✓ Transactions" if links['transactions']
  puts "  ✓ Batch Transactions" if links['batch_transactions']
  puts "  ✓ BPay Details" if links['bpay_details']
  puts "  ✓ NPP Details" if links['npp_details']
  puts "  ✓ Virtual Accounts" if links['virtual_accounts']
end
```

## Show Wallet Account User Example

### Example 1: Get User Associated with Wallet Account

Retrieve user details for a wallet account.

```ruby
# Get user associated with wallet account
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

response = wallet_accounts.show_user('5c1c6b10-4c56-0137-8cd7-0242ac110002')

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

### Example 2: Verify User Before Payment

Check user details before processing a payment from wallet account.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

begin
  # Step 1: Get user associated with wallet account
  user_response = wallet_accounts.show_user('wallet_account_id')
  
  if user_response.success?
    user = user_response.data
    
    # Step 2: Verify user details
    if user['verification_state'] == 'verified' && !user['held_state']
      puts "User verified and not on hold"
      puts "Name: #{user['full_name']}"
      puts "Email: #{user['email']}"
      
      # Proceed with payment
      puts "✓ Ready to process payment"
    else
      puts "Cannot process payment:"
      puts "  Verification: #{user['verification_state']}"
      puts "  On Hold: #{user['held_state']}"
    end
  end
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Wallet account not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Example 3: Get User Contact Information for Notifications

Retrieve user contact details for sending payment notifications.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

response = wallet_accounts.show_user('wallet_account_id')

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
  # NotificationService.send_payment_confirmation(contact_info)
end
```

## Pay a Bill Example

### Example 1: Basic Bill Payment

Pay a bill using funds from a wallet account.

```ruby
# Pay a bill from wallet account
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

response = wallet_accounts.pay_bill(
  '901d8cd0-6af3-0138-967d-0a58a9feac04',
  account_id: 'c1824ad0-73f1-0138-3700-0a58a9feac09',
  amount: 173,
  reference_id: 'test100'
)

if response.success?
  disbursement = response.data
  puts "Disbursement ID: #{disbursement['id']}"
  puts "Reference: #{disbursement['reference_id']}"
  puts "Amount: $#{disbursement['amount'] / 100.0}"
  puts "Currency: #{disbursement['currency']}"
  puts "State: #{disbursement['state']}"
  puts "To: #{disbursement['to']}"
  puts "Account Name: #{disbursement['account_name']}"
  puts "Biller Name: #{disbursement['biller_name']}"
  puts "Biller Code: #{disbursement['biller_code']}"
  puts "CRN: #{disbursement['crn']}"
  puts "Created At: #{disbursement['created_at']}"
  
  # Access links
  links = disbursement['links']
  puts "\nLinks:"
  puts "  Transactions: #{links['transactions']}"
  puts "  Wallet Accounts: #{links['wallet_accounts']}"
  puts "  BPay Accounts: #{links['bpay_accounts']}"
else
  puts "Failed to pay bill"
  puts "Error: #{response.error}"
end
```

### Example 2: Pay Bill with Balance Check

Check balance before paying a bill.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new
wallet_id = '901d8cd0-6af3-0138-967d-0a58a9feac04'
payment_amount = 17300  # $173.00

begin
  # Step 1: Check wallet balance
  wallet_response = wallet_accounts.show(wallet_id)
  
  if wallet_response.success?
    wallet = wallet_response.data
    balance = wallet['balance']
    
    puts "Current balance: $#{balance / 100.0}"
    puts "Payment amount: $#{payment_amount / 100.0}"
    
    # Step 2: Verify sufficient funds
    if balance >= payment_amount
      puts "Sufficient funds available"
      
      # Step 3: Process payment
      payment_response = wallet_accounts.pay_bill(
        wallet_id,
        account_id: 'bpay_account_id',
        amount: payment_amount,
        reference_id: "bill_#{Time.now.to_i}"
      )
      
      if payment_response.success?
        disbursement = payment_response.data
        puts "\n✓ Bill payment successful"
        puts "Disbursement ID: #{disbursement['id']}"
        puts "New balance: $#{(balance - payment_amount) / 100.0}"
      else
        puts "\n✗ Payment failed: #{payment_response.error}"
      end
    else
      shortfall = payment_amount - balance
      puts "\n✗ Insufficient funds"
      puts "Shortfall: $#{shortfall / 100.0}"
    end
  end
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Example 3: Pay Multiple Bills

Process multiple bill payments from a wallet account.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new
wallet_id = '901d8cd0-6af3-0138-967d-0a58a9feac04'

bills = [
  { 
    account_id: 'bpay_water_account', 
    amount: 15000,  # $150.00
    reference: 'water_bill_nov_2024',
    name: 'Water Bill'
  },
  { 
    account_id: 'bpay_electricity_account', 
    amount: 22000,  # $220.00
    reference: 'electricity_bill_nov_2024',
    name: 'Electricity Bill'
  },
  { 
    account_id: 'bpay_gas_account', 
    amount: 8500,  # $85.00
    reference: 'gas_bill_nov_2024',
    name: 'Gas Bill'
  }
]

# Check total payment amount
total_amount = bills.sum { |bill| bill[:amount] }
puts "Total payment amount: $#{total_amount / 100.0}"

# Check balance
wallet_response = wallet_accounts.show(wallet_id)
if wallet_response.success?
  balance = wallet_response.data['balance']
  puts "Available balance: $#{balance / 100.0}"
  
  if balance >= total_amount
    # Process each bill
    bills.each do |bill|
      response = wallet_accounts.pay_bill(
        wallet_id,
        account_id: bill[:account_id],
        amount: bill[:amount],
        reference_id: bill[:reference]
      )
      
      if response.success?
        disbursement = response.data
        puts "\n✓ #{bill[:name]} paid: $#{bill[:amount] / 100.0}"
        puts "  Disbursement ID: #{disbursement['id']}"
        puts "  State: #{disbursement['state']}"
      else
        puts "\n✗ Failed to pay #{bill[:name]}"
      end
      
      # Small delay between payments
      sleep(0.5)
    end
  else
    puts "\n✗ Insufficient funds for all bills"
    puts "Shortfall: $#{(total_amount - balance) / 100.0}"
  end
end
```

## Common Patterns

### Pattern 1: Complete Payment Workflow

Full workflow from balance check to payment confirmation.

```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new
wallet_id = '901d8cd0-6af3-0138-967d-0a58a9feac04'
bpay_account_id = 'c1824ad0-73f1-0138-3700-0a58a9feac09'
payment_amount = 17300  # $173.00

begin
  # Step 1: Verify user eligibility
  user_response = wallet_accounts.show_user(wallet_id)
  
  if user_response.success?
    user = user_response.data
    
    unless user['verification_state'] == 'verified' && !user['held_state']
      puts "User not eligible for payment"
      exit
    end
    
    puts "✓ User verified: #{user['full_name']}"
  end
  
  # Step 2: Check wallet balance
  wallet_response = wallet_accounts.show(wallet_id)
  
  if wallet_response.success?
    wallet = wallet_response.data
    balance = wallet['balance']
    
    unless wallet['active'] && balance >= payment_amount
      puts "✗ Wallet not ready for payment"
      puts "  Active: #{wallet['active']}"
      puts "  Balance: $#{balance / 100.0}"
      exit
    end
    
    puts "✓ Sufficient balance: $#{balance / 100.0}"
  end
  
  # Step 3: Process payment
  payment_response = wallet_accounts.pay_bill(
    wallet_id,
    account_id: bpay_account_id,
    amount: payment_amount,
    reference_id: "bill_#{Time.now.to_i}"
  )
  
  if payment_response.success?
    disbursement = payment_response.data
    
    puts "\n✓ Payment successful"
    puts "  Disbursement ID: #{disbursement['id']}"
    puts "  Amount: $#{disbursement['amount'] / 100.0}"
    puts "  State: #{disbursement['state']}"
    puts "  To: #{disbursement['account_name']}"
    puts "  Reference: #{disbursement['reference_id']}"
    
    # Step 4: Send notification
    # NotificationService.send_payment_confirmation(user['email'], disbursement)
  else
    puts "\n✗ Payment failed: #{payment_response.error}"
  end
  
rescue ZaiPayment::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  puts "Not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Pattern 2: Wallet Payment Service

Implement a payment service class for wallet payments.

```ruby
class WalletPaymentService
  def initialize
    @wallet_accounts = ZaiPayment::Resources::WalletAccount.new
  end
  
  def pay_bill(wallet_id, bpay_account_id, amount, reference_id)
    # Validate inputs
    validate_amount!(amount)
    
    # Check balance
    unless sufficient_balance?(wallet_id, amount)
      return { success: false, error: 'Insufficient balance' }
    end
    
    # Process payment
    response = @wallet_accounts.pay_bill(
      wallet_id,
      account_id: bpay_account_id,
      amount: amount,
      reference_id: reference_id
    )
    
    if response.success?
      disbursement = response.data
      
      {
        success: true,
        disbursement_id: disbursement['id'],
        amount: disbursement['amount'],
        state: disbursement['state'],
        reference: disbursement['reference_id']
      }
    else
      {
        success: false,
        error: response.error
      }
    end
  rescue ZaiPayment::Errors::ValidationError => e
    { success: false, error: "Validation error: #{e.message}" }
  rescue ZaiPayment::Errors::ApiError => e
    { success: false, error: "API error: #{e.message}" }
  end
  
  def get_balance(wallet_id)
    response = @wallet_accounts.show(wallet_id)
    
    if response.success?
      wallet = response.data
      {
        success: true,
        balance: wallet['balance'],
        currency: wallet['currency'],
        active: wallet['active']
      }
    else
      { success: false, error: response.error }
    end
  rescue ZaiPayment::Errors::ApiError => e
    { success: false, error: e.message }
  end
  
  private
  
  def validate_amount!(amount)
    raise ArgumentError, 'Amount must be positive' unless amount.positive?
    raise ArgumentError, 'Amount must be an integer' unless amount.is_a?(Integer)
  end
  
  def sufficient_balance?(wallet_id, amount)
    result = get_balance(wallet_id)
    result[:success] && result[:balance] >= amount
  end
end

# Usage
service = WalletPaymentService.new

# Check balance
balance_result = service.get_balance('wallet_id')
if balance_result[:success]
  puts "Balance: $#{balance_result[:balance] / 100.0}"
end

# Pay bill
payment_result = service.pay_bill(
  'wallet_id',
  'bpay_account_id',
  17300,
  'bill_123'
)

if payment_result[:success]
  puts "Payment successful: #{payment_result[:disbursement_id]}"
else
  puts "Payment failed: #{payment_result[:error]}"
end
```

### Pattern 3: Rails Controller for Wallet Payments

Implement wallet payments in a Rails controller.

```ruby
# In a Rails controller
class WalletPaymentsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    wallet_accounts = ZaiPayment::Resources::WalletAccount.new
    
    begin
      # Validate parameters
      validate_payment_params!
      
      # Process payment
      response = wallet_accounts.pay_bill(
        params[:wallet_account_id],
        account_id: params[:bpay_account_id],
        amount: params[:amount].to_i,
        reference_id: params[:reference_id]
      )
      
      if response.success?
        disbursement = response.data
        
        # Log payment
        Rails.logger.info("Payment successful: #{disbursement['id']}")
        
        render json: {
          success: true,
          disbursement_id: disbursement['id'],
          amount: disbursement['amount'],
          state: disbursement['state'],
          message: 'Bill payment successful'
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
    rescue ZaiPayment::Errors::NotFoundError => e
      render json: {
        success: false,
        message: 'Wallet or BPay account not found'
      }, status: :not_found
    rescue ZaiPayment::Errors::ApiError => e
      Rails.logger.error("Payment API error: #{e.message}")
      
      render json: {
        success: false,
        message: 'An error occurred while processing the payment'
      }, status: :internal_server_error
    end
  end
  
  def show_balance
    wallet_accounts = ZaiPayment::Resources::WalletAccount.new
    
    begin
      response = wallet_accounts.show(params[:id])
      
      if response.success?
        wallet = response.data
        
        render json: {
          success: true,
          balance: wallet['balance'],
          currency: wallet['currency'],
          active: wallet['active']
        }
      else
        render json: {
          success: false,
          message: response.error
        }, status: :unprocessable_entity
      end
    rescue ZaiPayment::Errors::NotFoundError => e
      render json: {
        success: false,
        message: 'Wallet account not found'
      }, status: :not_found
    end
  end
  
  private
  
  def validate_payment_params!
    required_params = [:wallet_account_id, :bpay_account_id, :amount]
    missing_params = required_params.select { |param| params[param].blank? }
    
    if missing_params.any?
      raise ActionController::ParameterMissing, "Missing parameters: #{missing_params.join(', ')}"
    end
    
    amount = params[:amount].to_i
    if amount <= 0
      raise ArgumentError, 'Amount must be positive'
    end
  end
end
```

## Important Notes

1. **Required Fields**:
   - `wallet_account_id` - The wallet account ID
   - `account_id` - BPay account ID (for pay_bill)
   - `amount` - Payment amount in cents (for pay_bill)

2. **Amount Validation**:
   - Must be a positive integer
   - Specified in cents (e.g., 100 = $1.00)
   - Cannot exceed wallet balance

3. **Reference ID**:
   - Optional but recommended for tracking
   - Cannot contain single quote (') character
   - Should be unique for each payment

4. **Balance Check**:
   - Always check balance before payment
   - Balance returned in cents
   - Verify wallet is active

5. **Disbursement States**:
   - `pending` - Payment initiated
   - `successful` - Payment completed
   - `failed` - Payment failed

6. **Error Handling**:
   - Always wrap API calls in error handling
   - Check for ValidationError, NotFoundError, ApiError
   - Log errors for debugging

7. **User Verification**:
   - Verify user state before payment
   - Check `verification_state` == 'verified'
   - Ensure `held_state` == false

