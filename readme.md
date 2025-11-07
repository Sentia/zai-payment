# Zai Payment Ruby Library

![GitHub License](https://img.shields.io/github/license/Sentia/zai-payment)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-MIT-blue.svg)](./code_of_conduct.md)
[![Gem Version](https://img.shields.io/gem/v/zai_payment.svg)](https://rubygems.org/gems/zai_payment)
[![GitHub release](https://img.shields.io/github/release/Sentia/zai-payment.svg)](https://github.com/Sentia/zai-payment/releases)
[![Gem](https://img.shields.io/gem/dt/zai_payment.svg)](https://rubygems.org/gems/zai_payment)
[![CI](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml/badge.svg)](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml)
![Endpoint Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FSentia%2Fzai-payment%2Fmain%2Fbadges%2Fcoverage.json)
![GitHub top language](https://img.shields.io/github/languages/top/Sentia/zai-payment)
[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-blue.svg)](https://rubydoc.info/gems/zai_payment?refresh=true)
[![Contributing](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](./contributing.md)

A lightweight and extensible Ruby client for the **Zai (AssemblyPay)** API — starting with secure OAuth2 authentication, and ready for Payments, Virtual Accounts, Webhooks, and more.

---

## ✨ Features

- 🔐 **OAuth2 Authentication** - Client Credentials flow with automatic token management  
- 🧠 **Smart Token Caching** - Auto-refresh before expiration, thread-safe storage  
- 👥 **User Management** - Create and manage payin (buyers) & payout (sellers) users  
- 📦 **Item Management** - Full CRUD for transactions/payments between buyers and sellers  
- 🏦 **Bank Account Management** - Complete CRUD + validation for AU/UK bank accounts  
- 💳 **BPay Account Management** - Manage BPay accounts for Australian bill payments  
- 💼 **Wallet Account Management** - Show wallet accounts, check balances, and pay bills via BPay  
- 🏦 **Virtual Accounts** - Complete virtual account management with PayTo and BPay support  
- 💳 **PayID Management** - Create and manage PayIDs for Australian NPP payments  
- 🎫 **Token Auth** - Generate secure tokens for bank and card account data collection  
- 🪝 **Webhooks** - Full CRUD + secure signature verification (HMAC SHA256)  
- 🧪 **Batch Transactions** - Prelive-only endpoints for testing batch transaction flows  
- ⚙️ **Environment-Aware** - Seamless Pre-live / Production switching  
- 🧱 **Modular & Extensible** - Clean resource-based architecture  
- 🧰 **Zero Heavy Dependencies** - Lightweight, fast, and reliable  
- 📦 **Production Ready** - 97%+ test coverage, RuboCop compliant  

---

## 🧭 Installation

Add this line to your Gemfile:

```ruby
gem 'zai_payment'
```

Then install

```bash
bundle install
```

## ⚙️ Configuration

```ruby
# config/initializers/zai_payment.rb
ZaiPayment.configure do |c|
  c.environment   = Rails.env.production? ? :production : :prelive
  c.client_id     = ENV.fetch("ZAI_CLIENT_ID")
  c.client_secret = ENV.fetch("ZAI_CLIENT_SECRET")
  c.scope         = ENV.fetch("ZAI_OAUTH_SCOPE")
  
  # Optional: Configure timeout settings (defaults shown)
  c.timeout       = 30  # General request timeout in seconds
  c.open_timeout  = 10  # Connection open timeout in seconds
  c.read_timeout  = 30  # Read timeout in seconds
end
```

## 🚀 Quick Start

### Authentication

Get an OAuth2 token with automatic caching and refresh:

```ruby
# Simple one-liner (recommended)
token = ZaiPayment.token

# Or with full control (advanced)
config = ZaiPayment::Config.new
config.environment = :prelive
config.client_id = 'your_client_id'
config.client_secret = 'your_client_secret'
config.scope = 'your_scope'

token_provider = ZaiPayment::Auth::TokenProvider.new(config: config)
token = token_provider.bearer_token
```

The gem handles OAuth2 Client Credentials flow automatically - tokens are cached and refreshed before expiration.

📖 **<a href="docs/authentication.md">Complete Authentication Guide</a>** - Two approaches, examples, and best practices

### Users

Manage payin (buyer) and payout (seller/merchant) users.

**📚 Documentation:**
- 📖 [User Management Guide](docs/users.md) - Complete guide for payin and payout users
- 💡 [User Examples](examples/users.md) - Real-world usage patterns and Rails integration
- 🔗 [Zai: Onboarding a Payin User](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- 🔗 [Zai: Onboarding a Payout User](https://developer.hellozai.com/docs/onboarding-a-pay-out-user)

### Items

Manage transactions/payments between buyers and sellers.

**📚 Documentation:**
- 📖 [Item Management Guide](docs/items.md) - Complete guide for creating and managing items
- 💡 [Item Examples](examples/items.md) - Real-world usage patterns and complete workflows
- 🔗 [Zai: Items API Reference](https://developer.hellozai.com/reference/listitems)

### Bank Accounts

Manage bank accounts for Australian and UK users, with routing number validation.

**📚 Documentation:**
- 📖 [Bank Account Management Guide](docs/bank_accounts.md) - Complete guide for bank accounts
- 💡 [Bank Account Examples](examples/bank_accounts.md) - Real-world patterns and integration
- 🔗 [Zai: Bank Accounts API Reference](https://developer.hellozai.com/reference/showbankaccount)

### BPay Accounts

Manage BPay accounts for Australian bill payments.

**📚 Documentation:**
- 📖 [BPay Account Management Guide](docs/bpay_accounts.md) - Complete guide for BPay accounts
- 💡 [BPay Account Examples](examples/bpay_accounts.md) - Real-world patterns and bill payment workflows
- 🔗 [Zai: BPay Accounts API Reference](https://developer.hellozai.com/reference/createbpayaccount)

### Wallet Accounts

Manage wallet accounts, check balances, and pay bills via BPay.

**📚 Documentation:**
- 📖 [Wallet Account Management Guide](docs/wallet_accounts.md) - Complete guide for wallet accounts
- 💡 [Wallet Account Examples](examples/wallet_accounts.md) - Real-world patterns and payment workflows
- 🔗 [Zai: Wallet Accounts API Reference](https://developer.hellozai.com/reference)

**Quick Example:**
```ruby
wallet_accounts = ZaiPayment::Resources::WalletAccount.new

# Check wallet balance
response = wallet_accounts.show('wallet_account_id')
balance = response.data['balance']  # in cents
puts "Balance: $#{balance / 100.0}"

# Pay a bill from wallet to BPay account
payment_response = wallet_accounts.pay_bill(
  'wallet_account_id',
  account_id: 'bpay_account_id',
  amount: 17300,  # $173.00 in cents
  reference_id: 'bill_nov_2024'
)

if payment_response.success?
  disbursement = payment_response.data
  puts "Payment successful: #{disbursement['id']}"
  puts "State: #{disbursement['state']}"
end
```

### Virtual Accounts

Manage virtual accounts with support for AKA names and Confirmation of Payee (CoP) lookups.

**📚 Documentation:**
- 📖 [Virtual Account Management Guide](docs/virtual_accounts.md) - Complete guide for virtual accounts
- 💡 [Virtual Account Examples](examples/virtual_accounts.md) - Real-world patterns and workflows
- 🔗 [Zai: Virtual Accounts API Reference](https://developer.hellozai.com/reference/overview-va)

### PayID

Register and manage PayIDs (EMAIL type) for Australian NPP (New Payments Platform) payments.

**📚 Documentation:**
- 📖 [PayID Management Guide](docs/pay_ids.md) - Complete guide for PayID registration
- 💡 [PayID Examples](examples/pay_ids.md) - Real-world patterns and workflows

### Token Auth

Generate secure tokens for collecting bank and card account information.

**📚 Documentation:**
- 💡 [Token Auth Examples](examples/token_auths.md) - Complete integration guide with PromisePay.js
- 🔗 [Zai: Generate Token API Reference](https://developer.hellozai.com/reference/generatetoken)

### Webhooks

Manage webhook endpoints with secure signature verification.

**📚 Documentation:**
- 📖 [Webhook Examples & Complete Guide](examples/webhooks.md) - Full CRUD operations and patterns
- 🔒 [Security Quick Start](docs/webhook_security_quickstart.md) - 5-minute webhook security setup
- 🏗️ [Architecture & Implementation](docs/webhooks.md) - Detailed technical documentation
- 🔐 [Signature Verification Details](docs/webhook_signature.md) - Security implementation specs

### Batch Transactions (Prelive Only)

Simulate batch transaction processing for testing in the prelive environment.

**📚 Documentation:**
- 📖 [Batch Transaction Guide](docs/batch_transactions.md) - Complete guide and method reference
- 💡 [Batch Transaction Examples](examples/batch_transactions.md) - Testing workflows and webhook simulation
- ⚠️ **Note:** These endpoints are only available in prelive environment

**Quick Example:**
```ruby
# Export pending transactions to batched state
export_response = ZaiPayment.batch_transactions.export_transactions
batch_id = export_response.data.first['batch_id']
transaction_ids = export_response.data.map { |t| t['id'] }

# Move to bank_processing state
ZaiPayment.batch_transactions.process_to_bank_processing(
  batch_id,
  exported_ids: transaction_ids
)

# Complete processing (triggers webhooks)
ZaiPayment.batch_transactions.process_to_successful(
  batch_id,
  exported_ids: transaction_ids
)
```

### Error Handling

The gem provides specific error classes for different scenarios:

```ruby
begin
  response = ZaiPayment.webhooks.create(
    url: 'https://example.com/webhook',
    object_type: 'transactions'
  )
rescue ZaiPayment::Errors::ValidationError => e
  # Handle validation errors (400, 422)
  puts "Validation error: #{e.message}"
rescue ZaiPayment::Errors::UnauthorizedError => e
  # Handle authentication errors (401)
  puts "Authentication failed: #{e.message}"
rescue ZaiPayment::Errors::NotFoundError => e
  # Handle not found errors (404)
  puts "Resource not found: #{e.message}"
rescue ZaiPayment::Errors::ApiError => e
  # Handle other API errors
  puts "API error: #{e.message}"
end
```

## 🧩 Roadmap

| Area                            | Description                       | Status         |
| ------------------------------- | --------------------------------- | -------------- |
| ✅ Authentication                | OAuth2 Client Credentials flow    | Done           |
| ✅ Webhooks                     | CRUD for webhook endpoints        | Done           |
| ✅ Users                        | Manage PayIn / PayOut users       | Done           |
| ✅ Items                        | Transactions/payments (CRUD)      | Done           |
| ✅ Bank Accounts                | AU/UK bank accounts + validation  | Done           |
| ✅ BPay Accounts                | Manage BPay accounts              | Done           |
| ✅ Wallet Accounts              | Show, check balance, pay bills    | Done           |
| ✅ Token Auth                   | Generate bank/card tokens         | Done           |
| ✅ Batch Transactions (Prelive) | Simulate batch processing flows   | Done           |
| ✅ Payments                     | Single and recurring payments     | Done           |
| ✅ Virtual Accounts             | Manage virtual accounts & PayTo   | Done           |
| ✅ PayID                        | Create and manage PayIDs          | Done           |

## 🧪 Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
bundle exec rspec
```

### Code Quality

This project uses RuboCop for linting. Run it with:

```bash
bundle exec rubocop
```

### Interactive Console

For development and testing, use the interactive console:

```bash
bin/console
```

This will load the gem and all its dependencies, allowing you to experiment with the API in a REPL environment.

## 🧾 Versioning
This gem follows [Semantic Versioning](https://semver.org).

See [changelog.md](./changelog.md) for release history.


## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Sentia/zai-payment. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Sentia/zai-payment/blob/main/code_of_conduct.md).

## 🪪 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ZaiPayment project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Sentia/zai-payment/blob/main/code_of_conduct.md).

## 📚 Documentation

### Getting Started
- [**Authentication Guide**](docs/authentication.md) - Two approaches to getting tokens, automatic management
- [**User Management Guide**](docs/users.md) - Managing payin and payout users
- [**Item Management Guide**](docs/items.md) - Creating and managing transactions/payments
- [**Bank Account Guide**](docs/bank_accounts.md) - Managing bank accounts for AU/UK users
- [**BPay Account Guide**](docs/bpay_accounts.md) - Managing BPay accounts for Australian bill payments
- [**Wallet Account Guide**](docs/wallet_accounts.md) - Managing wallet accounts, checking balances, and paying bills
- [**Virtual Account Guide**](docs/virtual_accounts.md) - Managing virtual accounts with PayTo and BPay support
- [**PayID Guide**](docs/pay_ids.md) - Creating and managing PayIDs for Australian NPP payments
- [**Webhook Examples**](examples/webhooks.md) - Complete webhook usage guide
- [**Documentation Index**](docs/readme.md) - Full documentation navigation

### Examples & Patterns
- [User Examples](examples/users.md) - Real-world user management patterns
- [Item Examples](examples/items.md) - Transaction and payment workflows
- [Bank Account Examples](examples/bank_accounts.md) - Bank account integration patterns
- [BPay Account Examples](examples/bpay_accounts.md) - BPay account integration patterns
- [Wallet Account Examples](examples/wallet_accounts.md) - Wallet account and bill payment workflows
- [Virtual Account Examples](examples/virtual_accounts.md) - Virtual account management and PayTo workflows
- [PayID Examples](examples/pay_ids.md) - PayID creation and management workflows
- [Token Auth Examples](examples/token_auths.md) - Secure token generation and integration
- [Webhook Examples](examples/webhooks.md) - Webhook integration patterns
- [Batch Transaction Examples](examples/batch_transactions.md) - Testing batch transaction flows (prelive only)

### Technical Guides
- [Webhook Architecture](docs/webhooks.md) - Technical implementation details
- [Architecture Overview](docs/architecture.md) - System architecture and design
- [**Direct API Usage Guide**](docs/direct_api_usage.md) - 🔥 How to call unimplemented APIs directly

### Security
- [Webhook Security Quick Start](docs/webhook_security_quickstart.md) - 5-minute setup guide
- [Signature Verification](docs/webhook_signature.md) - Implementation details

### External Resources
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [Zai OAuth Documentation](https://developer.hellozai.com/docs/introduction)
