# Zai Payment Ruby Library

![GitHub License](https://img.shields.io/github/license/Sentia/zai-payment)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-MIT-blue.svg)](./CODE_OF_CONDUCT.md)
[![Gem Version](https://badge.fury.io/rb/zai_payment.svg)](https://badge.fury.io/rb/zai_payment)
[![GitHub release](https://img.shields.io/github/release/Sentia/zai-payment.svg)](https://github.com/Sentia/zai-payment/releases)
[![Gem](https://img.shields.io/gem/dt/zai_payment.svg)](https://rubygems.org/gems/zai_payment)
[![CI](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml/badge.svg)](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml)
![Endpoint Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FSentia%2Fzai-payment%2Fmain%2Fbadges%2Fcoverage.json)
![GitHub top language](https://img.shields.io/github/languages/top/Sentia/zai-payment)
[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-blue.svg)](https://rubydoc.info/gems/zai_payment)
[![Contributing](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](./CONTRIBUTING.md)

A lightweight and extensible Ruby client for the **Zai (AssemblyPay)** API — starting with secure OAuth2 authentication, and ready for Payments, Virtual Accounts, Webhooks, and more.

---

## ✨ Features

- 🔐 **OAuth2 Authentication** - Client Credentials flow with automatic token management  
- 🧠 **Smart Token Caching** - Auto-refresh before expiration, thread-safe storage  
- 👥 **User Management** - Create and manage payin (buyers) & payout (sellers) users  
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

📖 **[Complete Authentication Guide](docs/AUTHENTICATION.md)** - Two approaches, examples, and best practices

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
  dob: '19900101',
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
```

**📚 Documentation:**
- 📖 [User Management Guide](docs/USERS.md) - Complete guide for payin and payout users
- 💡 [User Examples](examples/users.md) - Real-world usage patterns and Rails integration
- 🔗 [Zai: Onboarding a Payin User](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- 🔗 [Zai: Onboarding a Payout User](https://developer.hellozai.com/docs/onboarding-a-pay-out-user)

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
- 🔒 [Security Quick Start](docs/WEBHOOK_SECURITY_QUICKSTART.md) - 5-minute webhook security setup
- 🏗️ [Architecture & Implementation](docs/WEBHOOKS.md) - Detailed technical documentation
- 🔐 [Signature Verification Details](docs/WEBHOOK_SIGNATURE.md) - Security implementation specs

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

See [CHANGELOG.md](./CHANGELOG.md) for release history.


## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Sentia/zai-payment. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Sentia/zai-payment/blob/main/CODE_OF_CONDUCT.md).

## 🪪 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ZaiPayment project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Sentia/zai-payment/blob/main/CODE_OF_CONDUCT.md).

## 📚 Documentation

### Getting Started
- [**Authentication Guide**](docs/AUTHENTICATION.md) - Two approaches to getting tokens, automatic management
- [**User Management Guide**](docs/USERS.md) - Managing payin and payout users
- [**Webhook Examples**](examples/webhooks.md) - Complete webhook usage guide
- [**Documentation Index**](docs/README.md) - Full documentation navigation

### Examples & Patterns
- [User Examples](examples/users.md) - Real-world user management patterns
- [Webhook Examples](examples/webhooks.md) - Webhook integration patterns

### Technical Guides
- [Webhook Architecture](docs/WEBHOOKS.md) - Technical implementation details
- [Architecture Overview](docs/ARCHITECTURE.md) - System architecture and design

### Security
- [Webhook Security Quick Start](docs/WEBHOOK_SECURITY_QUICKSTART.md) - 5-minute setup guide
- [Signature Verification](docs/WEBHOOK_SIGNATURE.md) - Implementation details

### External Resources
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [Zai OAuth Documentation](https://developer.hellozai.com/docs/introduction)
