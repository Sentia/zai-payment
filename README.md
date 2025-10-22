# Zai Payment Ruby Library

[![CI](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml/badge.svg)](https://github.com/Sentia/zai-payment/actions/workflows/ci.yml)

A lightweight and extensible Ruby client for the **Zai (AssemblyPay)** API — starting with secure OAuth2 authentication, and ready for Payments, Virtual Accounts, Webhooks, and more.

---

## ✨ Features

- 🔐 OAuth2 Client Credentials authentication with automatic token management  
- 🧠 Smart token caching and refresh  
- ⚙️ Environment-aware (Pre-live / Production)  
- 🧱 Modular structure: easy to extend to Payments, Wallets, Webhooks, etc.  
- 🧩 Thread-safe in-memory store (Redis support coming soon)  
- 🧰 Simple Ruby API, no heavy dependencies  

---

## 🧭 Installation

### From GitHub (private repo)
Add this line to your Gemfile:

```ruby
gem 'zai_payment', '~> 1.0', '>= 1.0.2'
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

## 🚀 Authentication

The Zai Payment gem implements OAuth2 Client Credentials flow for secure authentication with the Zai API. The gem intelligently manages your authentication tokens behind the scenes, so you don't have to worry about token expiration or manual refreshes.

When you request a token, the gem automatically caches it and reuses it for subsequent requests. Since Zai tokens expire after 60 minutes, the gem monitors the token lifetime and seamlessly refreshes it before expiration — ensuring your API calls never fail due to stale credentials.

This automatic token management means you can focus on building your integration while the gem handles all the authentication complexity for you. Simply configure your credentials once, and the gem takes care of the rest.

For more details about Zai's OAuth2 authentication, see the [official documentation](https://developer.hellozai.com/reference/overview#authentication).

```ruby
client = ZaiPayment::Auth::TokenProvider.new(config: ZaiPayment.config)

client.bearer_token
```

Or, more easily, you can get a token with the convenience one-liner:


```ruby
ZaiPayment.token
```

## 🚀 Usage

### Webhooks

The gem provides a comprehensive interface for managing Zai webhooks:

```ruby
# List all webhooks
response = ZaiPayment.webhooks.list
webhooks = response.data

# List with pagination
response = ZaiPayment.webhooks.list(limit: 20, offset: 10)

# Get a specific webhook
response = ZaiPayment.webhooks.show('webhook_id')
webhook = response.data

# Create a webhook
response = ZaiPayment.webhooks.create(
  url: 'https://example.com/webhooks/zai',
  object_type: 'transactions',
  enabled: true,
  description: 'Production webhook for transactions'
)

# Update a webhook
response = ZaiPayment.webhooks.update(
  'webhook_id',
  enabled: false,
  description: 'Temporarily disabled'
)

# Delete a webhook
response = ZaiPayment.webhooks.delete('webhook_id')
```

For more examples, see [examples/webhooks.rb](examples/webhooks.rb).

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
| 💳 Payments                     | Single and recurring payments     | 🚧 In progress |
| 🏦 Virtual Accounts (VA / PIPU) | Manage virtual accounts & PayTo   | ⏳ Planned      |
| 👤 Users                        | Manage PayIn / PayOut users       | ⏳ Planned      |
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

## 🔗 Resources

- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [AssemblyPay Auth Documentation](https://developer.hellozai.com/docs/introduction)
