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
- 🎫 **Token Auth** - Generate secure tokens for bank and card account data collection  
- 🪝 **Webhooks** - Full CRUD + secure signature verification (HMAC SHA256)  
- ⚙️ **Environment-Aware** - Seamless Pre-live / Production switching  
- 🧱 **Modular & Extensible** - Clean resource-based architecture  
- 🧰 **Zero Heavy Dependencies** - Lightweight, fast, and reliable  
- 📦 **Production Ready** - 88%+ test coverage, RuboCop compliant  

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

Manage payin (buyer) and payout (seller/merchant) users:

```ruby
# Create a payin user (buyer)
response = ZaiPayment.users.create(
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA',
  mobile: '+1234567890'
)

# Create a payout user (seller/merchant)
response = ZaiPayment.users.create(
  email: 'seller@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS',
  dob: '01/01/1990',
  address_line1: '456 Market St',
  city: 'Sydney',
  state: 'NSW',
  zip: '2000'
)

# Create a business user with company details
response = ZaiPayment.users.create(
  email: 'director@company.com',
  first_name: 'John',
  last_name: 'Director',
  country: 'AUS',
  mobile: '+61412345678',
  authorized_signer_title: 'Director',
  company: {
    name: 'My Company',
    legal_name: 'My Company Pty Ltd',
    tax_number: '123456789',
    business_email: 'admin@company.com',
    country: 'AUS',
    charge_tax: true
  }
)

# List users
response = ZaiPayment.users.list(limit: 10, offset: 0)

# Get user details
response = ZaiPayment.users.show('user_id')

# Update user
response = ZaiPayment.users.update('user_id', mobile: '+9876543210')

# Show user wallet account
response = ZaiPayment.users.wallet_account('user_id')

# List user items with pagination
response = ZaiPayment.users.items('user_id', limit: 50, offset: 10)

# Set user disbursement account
response = ZaiPayment.users.set_disbursement_account('user_id', 'bank_account_id')

# Show user bank account
response = ZaiPayment.users.bank_account('user_id')

# Verify user (prelive only)
response = ZaiPayment.users.verify('user_id')

# Show user card account
response = ZaiPayment.users.card_account('user_id')

# List user's BPay accounts
response = ZaiPayment.users.bpay_accounts('user_id')
```

**📚 Documentation:**
- 📖 [User Management Guide](docs/users.md) - Complete guide for payin and payout users
- 💡 [User Examples](examples/users.md) - Real-world usage patterns and Rails integration
- 🔗 [Zai: Onboarding a Payin User](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- 🔗 [Zai: Onboarding a Payout User](https://developer.hellozai.com/docs/onboarding-a-pay-out-user)

### Items

Manage transactions/payments between buyers and sellers:

```ruby
# Create an item
response = ZaiPayment.items.create(
  name: "Product Purchase",
  amount: 10000, # Amount in cents ($100.00)
  payment_type: 2, # Credit card
  buyer_id: "buyer-123",
  seller_id: "seller-456",
  description: "Purchase of premium product",
  currency: "AUD",
  tax_invoice: true
)

# List items
response = ZaiPayment.items.list(limit: 20, offset: 0)

# Get item details
response = ZaiPayment.items.show('item_id')

# Update item
response = ZaiPayment.items.update('item_id', name: 'Updated Name')

# Get item status
response = ZaiPayment.items.show_status('item_id')

# Get buyer/seller details
response = ZaiPayment.items.show_buyer('item_id')
response = ZaiPayment.items.show_seller('item_id')

# List transactions
response = ZaiPayment.items.list_transactions('item_id')
```

**📚 Documentation:**
- 📖 [Item Management Guide](docs/items.md) - Complete guide for creating and managing items
- 💡 [Item Examples](examples/items.md) - Real-world usage patterns and complete workflows
- 🔗 [Zai: Items API Reference](https://developer.hellozai.com/reference/listitems)

### Token Auth

Generate secure tokens for collecting bank and card account information:

```ruby
# Generate a bank token (for collecting bank account details)
response = ZaiPayment.token_auths.generate(
  user_id: "seller-68611249",
  token_type: "bank"
)

token = response.data['token_auth']['token']
# Use this token with PromisePay.js on the frontend

# Generate a card token (for collecting credit card details)
response = ZaiPayment.token_auths.generate(
  user_id: "buyer-12345",
  token_type: "card"
)

token = response.data['token_auth']['token']
# Use this token with PromisePay.js on the frontend
```

**📚 Documentation:**
- 💡 [Token Auth Examples](examples/token_auths.md) - Complete integration guide with PromisePay.js
- 🔗 [Zai: Generate Token API Reference](https://developer.hellozai.com/reference/generatetoken)

### Webhooks

Manage webhook endpoints:

```ruby
# List webhooks
response = ZaiPayment.webhooks.list
webhooks = response.data

# Create a webhook
response = ZaiPayment.webhooks.create(
  url: 'https://example.com/webhooks/zai',
  object_type: 'transactions',
  enabled: true
)

# Secure your webhooks with signature verification
secret_key = SecureRandom.alphanumeric(32)
ZaiPayment.webhooks.create_secret_key(secret_key: secret_key)
```

**📚 Documentation:**
- 📖 [Webhook Examples & Complete Guide](examples/webhooks.md) - Full CRUD operations and patterns
- 🔒 [Security Quick Start](docs/webhook_security_quickstart.md) - 5-minute webhook security setup
- 🏗️ [Architecture & Implementation](docs/webhooks.md) - Detailed technical documentation
- 🔐 [Signature Verification Details](docs/webhook_signature.md) - Security implementation specs

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
| ✅ Token Auth                   | Generate bank/card tokens         | Done           |
| 💳 Payments                     | Single and recurring payments     | 🚧 In progress |
| 🏦 Virtual Accounts (VA / PIPU) | Manage virtual accounts & PayTo   | ⏳ Planned      |
| 💼 Wallets                      | Create and manage wallet accounts | ⏳ Planned      |

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
- [**Webhook Examples**](examples/webhooks.md) - Complete webhook usage guide
- [**Documentation Index**](docs/readme.md) - Full documentation navigation

### Examples & Patterns
- [User Examples](examples/users.md) - Real-world user management patterns
- [Item Examples](examples/items.md) - Transaction and payment workflows
- [Token Auth Examples](examples/token_auths.md) - Secure token generation and integration
- [Webhook Examples](examples/webhooks.md) - Webhook integration patterns

### Technical Guides
- [Webhook Architecture](docs/webhooks.md) - Technical implementation details
- [Architecture Overview](docs/architecture.md) - System architecture and design

### Security
- [Webhook Security Quick Start](docs/webhook_security_quickstart.md) - 5-minute setup guide
- [Signature Verification](docs/webhook_signature.md) - Implementation details

### External Resources
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [Zai OAuth Documentation](https://developer.hellozai.com/docs/introduction)
