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
- 🎫 **Token Auth** - Generate secure tokens for bank and card account data collection  
- 🪝 **Webhooks** - Full CRUD + secure signature verification (HMAC SHA256)  
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
- [**Bank Account Guide**](docs/bank_accounts.md) - Managing bank accounts for AU/UK users
- [**Webhook Examples**](examples/webhooks.md) - Complete webhook usage guide
- [**Documentation Index**](docs/readme.md) - Full documentation navigation

### Examples & Patterns
- [User Examples](examples/users.md) - Real-world user management patterns
- [Item Examples](examples/items.md) - Transaction and payment workflows
- [Bank Account Examples](examples/bank_accounts.md) - Bank account integration patterns
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
