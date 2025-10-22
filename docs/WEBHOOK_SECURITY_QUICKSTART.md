# Quick Start: Webhook Security

## 🚀 5-Minute Setup

### Step 1: Generate & Register Secret Key (One Time)

```ruby
require 'securerandom'

secret_key = SecureRandom.alphanumeric(32)
ZaiPayment.webhooks.create_secret_key(secret_key: secret_key)

# Save to your .env file
# ZAI_WEBHOOK_SECRET=your_generated_secret_key
```

### Step 2: Add Verification to Your Webhook Endpoint

```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def zai_webhook
    payload = request.body.read
    signature = request.headers['Webhooks-signature']
    
    # ✅ Verify signature
    unless verify_webhook(payload, signature)
      return render json: { error: 'Invalid signature' }, status: :unauthorized
    end
    
    # 🎉 Process your webhook
    webhook_data = JSON.parse(payload)
    handle_webhook(webhook_data)
    
    render json: { status: 'success' }
  end

  private

  def verify_webhook(payload, signature)
    ZaiPayment.webhooks.verify_signature(
      payload: payload,
      signature_header: signature,
      secret_key: ENV['ZAI_WEBHOOK_SECRET'],
      tolerance: 300 # 5 minutes
    )
  rescue ZaiPayment::Errors::ValidationError
    false
  end

  def handle_webhook(data)
    case data['event']
    when 'transaction.created'
      # Your logic here
    when 'transaction.completed'
      # Your logic here
    end
  end
end
```

### Step 3: Add Route

```ruby
# config/routes.rb
post '/webhooks/zai', to: 'webhooks#zai_webhook'
```

## 🧪 Testing

```ruby
# spec/controllers/webhooks_controller_spec.rb
RSpec.describe WebhooksController do
  let(:secret_key) { ENV['ZAI_WEBHOOK_SECRET'] }
  let(:payload) { { event: 'transaction.updated' }.to_json }
  
  it 'accepts valid webhooks' do
    timestamp = Time.now.to_i
    signature = ZaiPayment::Resources::Webhook.new.generate_signature(
      payload, secret_key, timestamp
    )
    
    request.headers['Webhooks-signature'] = "t=#{timestamp},v=#{signature}"
    post :zai_webhook, body: payload
    
    expect(response).to have_http_status(:ok)
  end
  
  it 'rejects invalid signatures' do
    request.headers['Webhooks-signature'] = "t=#{Time.now.to_i},v=bad_signature"
    post :zai_webhook, body: payload
    
    expect(response).to have_http_status(:unauthorized)
  end
end
```

## 🔐 Security Checklist

- ✅ Secret key is at least 32 bytes
- ✅ Secret key stored in environment variables (not in code)
- ✅ Using HTTPS for webhook endpoint
- ✅ Signature verification before processing
- ✅ Timestamp tolerance configured appropriately
- ✅ Error logging for failed verifications
- ✅ Tests cover both valid and invalid scenarios

## 🐛 Common Issues

### "Invalid signature header: missing or invalid timestamp"
**Fix**: Ensure header format is `t=timestamp,v=signature`

### "Webhook timestamp is outside tolerance"
**Fix**: Check server clock synchronization or increase tolerance

### Signature doesn't match
**Fix**: 
- Use raw request body (don't parse it first)
- Verify secret key matches what was registered
- Check for encoding issues

## 📚 Full Documentation

- [Complete Setup Guide](docs/WEBHOOKS.md#webhook-security-signature-verification)
- [More Examples](examples/webhooks.md#webhook-security-complete-setup-guide)
- [Zai Official Docs](https://developer.hellozai.com/docs/verify-webhook-signatures)

## 💡 Pro Tips

1. **Use Background Jobs**: Process webhooks asynchronously for better performance
2. **Implement Idempotency**: Check if webhook was already processed
3. **Add Rate Limiting**: Protect against DoS attacks
4. **Log Everything**: Monitor for suspicious activity
5. **Test Replay Attacks**: Ensure old webhooks are rejected

---

**Need Help?** See the [full implementation guide](WEBHOOK_SIGNATURE_IMPLEMENTATION.md)

