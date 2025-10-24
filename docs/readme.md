# Documentation Index

Welcome to the Zai Payment Ruby gem documentation. This guide will help you find the information you need.

## 📖 Getting Started

**New to the gem?** Start here:
1. [Main README](../README.md) - Installation and basic configuration
2. [Authentication Guide](AUTHENTICATION.md) - Get tokens with two approaches (short & long way)
3. [Webhook Quick Start](WEBHOOK_SECURITY_QUICKSTART.md) - Set up secure webhooks in 5 minutes
4. [Webhook Examples](../examples/webhooks.md) - Complete usage examples

## 🏗️ Architecture & Design

- [**ARCHITECTURE.md**](ARCHITECTURE.md) - System architecture and design principles
- [**AUTHENTICATION.md**](AUTHENTICATION.md) - OAuth2 implementation, token management, two approaches
- [**WEBHOOKS.md**](WEBHOOKS.md) - Webhook implementation details, best practices, and patterns

## 🔐 Security Guides

- [**WEBHOOK_SECURITY_QUICKSTART.md**](WEBHOOK_SECURITY_QUICKSTART.md) - Quick 5-minute security setup guide
- [**WEBHOOK_SIGNATURE.md**](WEBHOOK_SIGNATURE.md) - Detailed signature verification implementation

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
- **Getting Started**: [Authentication Guide](AUTHENTICATION.md)
- **Short Way**: `ZaiPayment.token` (one-liner)
- **Long Way**: `TokenProvider.new(config: config).bearer_token` (full control)

### Webhooks
- **Setup**: [Quick Start Guide](WEBHOOK_SECURITY_QUICKSTART.md)
- **Examples**: [Complete Examples](../examples/webhooks.md)
- **Details**: [Technical Documentation](WEBHOOKS.md)
- **Security**: [Signature Verification](WEBHOOK_SIGNATURE.md)

### External Resources
- [Zai Developer Portal](https://developer.hellozai.com/)
- [Zai API Reference](https://developer.hellozai.com/reference)
- [Webhook Signature Docs](https://developer.hellozai.com/docs/verify-webhook-signatures)

## 📚 Documentation Structure

```
docs/
├── README.md                        # This file - documentation index
├── AUTHENTICATION.md                # OAuth2 authentication guide (NEW!)
├── ARCHITECTURE.md                  # System architecture
├── WEBHOOKS.md                      # Webhook technical docs
├── WEBHOOK_SECURITY_QUICKSTART.md   # Quick security setup
└── WEBHOOK_SIGNATURE.md             # Signature implementation

examples/
└── webhooks.md                      # Complete webhook examples
```

## 💡 Tips

- **Getting tokens?** Check [AUTHENTICATION.md](AUTHENTICATION.md) for both approaches
- **Looking for code examples?** Check [examples/webhooks.md](../examples/webhooks.md)
- **Need quick setup?** See [WEBHOOK_SECURITY_QUICKSTART.md](WEBHOOK_SECURITY_QUICKSTART.md)
- **Want to understand the design?** Read [ARCHITECTURE.md](ARCHITECTURE.md)
- **Security details?** Review [WEBHOOK_SIGNATURE.md](WEBHOOK_SIGNATURE.md)

## 🆘 Need Help?

1. Check the relevant documentation section above
2. Review the [examples](../examples/webhooks.md)
3. Consult the [Zai API documentation](https://developer.hellozai.com/)
4. Open an issue on GitHub

