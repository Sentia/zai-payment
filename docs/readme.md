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
- [**webhooks.md**](webhooks.md) - Webhook implementation details, best practices, and patterns

## 🔐 Security Guides

- [**webhook_security_quickstart.md**](webhook_security_quickstart.md) - Quick 5-minute security setup guide
- [**webhook_signature.md**](webhook_signature.md) - Detailed signature verification implementation

## 📝 Examples

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
├── authentication.md                # OAuth2 authentication guide (NEW!)
├── architecture.md                  # System architecture
├── webhooks.md                      # Webhook technical docs
├── webhook_security_quickstart.md   # Quick security setup
└── webhook_signature.md             # Signature implementation

examples/
└── webhooks.md                      # Complete webhook examples
```

## 💡 Tips

- **Getting tokens?** Check [authentication.md](authentication.md) for both approaches
- **Looking for code examples?** Check [examples/webhooks.md](../examples/webhooks.md)
- **Need quick setup?** See [webhook_security_quickstart.md](webhook_security_quickstart.md)
- **Want to understand the design?** Read [architecture.md](architecture.md)
- **Security details?** Review [webhook_signature.md](webhook_signature.md)

## 🆘 Need Help?

1. Check the relevant documentation section above
2. Review the [examples](../examples/webhooks.md)
3. Consult the [Zai API documentation](https://developer.hellozai.com/)
4. Open an issue on GitHub

