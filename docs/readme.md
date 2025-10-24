# Documentation Index

Welcome to the Zai Payment Ruby gem documentation. This guide will help you find the information you need.

## 📖 Getting Started

**New to the gem?** Start here:
1. [Main README](../readme.md) - Installation and basic configuration
2. [Authentication Guide](authentication.md) - Get tokens with two approaches (short & long way)
3. [Webhook Quick Start](webhook_security_quickstart.md) - Set up secure webhooks in 5 minutes
4. [Webhook Examples](../examples/webhooks.md) - Complete usage examples

## 🏗️ Architecture & Design

- [**architecture.md**](architecture.md) - System architecture and design principles
- [**authentication.md**](authentication.md) - OAuth2 implementation, token management, two approaches
- [**users.md**](users.md) - User management for payin (buyers) and payout (sellers/merchants)
- [**items.md**](items.md) - Item management for transactions and payments
- [**token_auths.md**](token_auths.md) - Token generation for secure bank and card data collection
- [**webhooks.md**](webhooks.md) - Webhook implementation details, best practices, and patterns

## 🔐 Security Guides

- [**webhook_security_quickstart.md**](webhook_security_quickstart.md) - Quick 5-minute security setup guide
- [**webhook_signature.md**](webhook_signature.md) - Detailed signature verification implementation

## 📝 Examples

- [**User Examples**](../examples/users.md) - User management examples and patterns
- [**Item Examples**](../examples/items.md) - Transaction and payment workflows
- [**Token Auth Examples**](../examples/token_auths.md) - Token generation and PromisePay.js integration
- [**Webhook Examples**](../examples/webhooks.md) - Comprehensive webhook usage examples including:
  - Basic CRUD operations
  - Rails controller implementation
  - Sinatra example
  - Rack middleware
  - Background job processing
  - Idempotency patterns

## 🔗 Quick Links

### Authentication
- **Getting Started**: [Authentication Guide](authentication.md)
- **Short Way**: `ZaiPayment.token` (one-liner)
- **Long Way**: `TokenProvider.new(config: config).bearer_token` (full control)

### Users
- **Guide**: [User Management](users.md)
- **Examples**: [User Examples](../examples/users.md)
- **API Reference**: [Zai Users API](https://developer.hellozai.com/reference/getallusers)

### Items
- **Guide**: [Item Management](items.md)
- **Examples**: [Item Examples](../examples/items.md)
- **API Reference**: [Zai Items API](https://developer.hellozai.com/reference/listitems)

### Token Auth
- **Guide**: [Token Auth](token_auths.md)
- **Examples**: [Token Auth Examples](../examples/token_auths.md)
- **API Reference**: [Zai Generate Token API](https://developer.hellozai.com/reference/generatetoken)

### Webhooks
- **Setup**: [Quick Start Guide](webhook_security_quickstart.md)
- **Examples**: [Complete Examples](../examples/webhooks.md)
- **Details**: [Technical Documentation](webhooks.md)
- **Security**: [Signature Verification](webhook_signature.md)

### External Resources
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [Webhook Signature Docs](https://developer.hellozai.com/docs/verify-webhook-signatures)

## 📚 Documentation Structure

```
docs/
├── readme.md                        # This file - documentation index
├── authentication.md                # OAuth2 authentication guide
├── users.md                         # User management guide
├── items.md                         # Item management guide
├── token_auths.md                   # Token generation guide (NEW!)
├── architecture.md                  # System architecture
├── webhooks.md                      # Webhook technical docs
├── webhook_security_quickstart.md   # Quick security setup
└── webhook_signature.md             # Signature implementation

examples/
├── users.md                         # User management examples
├── items.md                         # Item examples
├── token_auths.md                   # Token auth examples (NEW!)
└── webhooks.md                      # Webhook examples
```

## 💡 Tips

- **Getting tokens?** Check [authentication.md](authentication.md) for both approaches
- **Managing users?** See [users.md](users.md) for payin and payout user guides
- **Creating transactions?** Review [items.md](items.md) for item management
- **Collecting payment data?** See [token_auths.md](token_auths.md) for secure token generation
- **Looking for code examples?** Check the [examples](../examples/) directory
- **Need quick setup?** See [webhook_security_quickstart.md](webhook_security_quickstart.md)
- **Want to understand the design?** Read [architecture.md](architecture.md)
- **Security details?** Review [webhook_signature.md](webhook_signature.md)

## 🆘 Need Help?

1. Check the relevant documentation section above
2. Review the [examples](../examples/)
3. Consult the [Zai API documentation](https://developer.hellozai.com/)
4. Open an issue on GitHub

