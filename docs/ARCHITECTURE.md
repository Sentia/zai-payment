# Zai Payment Webhook Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Application                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ ZaiPayment.webhooks.list()
                         │ ZaiPayment.webhooks.create(...)
                         │ ZaiPayment.webhooks.update(...)
                         │ ZaiPayment.webhooks.delete(...)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ZaiPayment (Module)                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  config()       - Configuration singleton                 │  │
│  │  auth()         - TokenProvider singleton                 │  │
│  │  webhooks()     - Webhook resource singleton              │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌──────────────────┐          ┌──────────────────────┐
│   Config         │          │  Auth::TokenProvider │
│  ─────────────   │          │  ──────────────────  │
│  - environment   │◄─────────│  Uses config         │
│  - client_id     │          │  - bearer_token()    │
│  - client_secret │          │  - refresh_token()   │
│  - scope         │          │  - clear_token()     │
│  - endpoints()   │          │                      │
└──────────────────┘          └──────────────────────┘
                                        │
                                        │
                                        ▼
                              ┌──────────────────────┐
                              │   TokenStore         │
                              │  ──────────────────  │
                              │  (MemoryStore)       │
                              │  - fetch()           │
                              │  - write()           │
                              │  - clear()           │
                              └──────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Resources::Webhook (Resource Layer)                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  list(limit:, offset:)                                    │  │
│  │  show(webhook_id)                                         │  │
│  │  create(url:, object_type:, enabled:, description:)       │  │
│  │  update(webhook_id, ...)                                  │  │
│  │  delete(webhook_id)                                       │  │
│  │                                                           │  │
│  │  Private validation methods:                              │  │
│  │  - validate_id!()                                         │  │
│  │  - validate_presence!()                                   │  │
│  │  - validate_url!()                                        │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Client (HTTP Layer)                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  get(path, params:)                                       │  │
│  │  post(path, body:)                                        │  │
│  │  patch(path, body:)                                       │  │
│  │  delete(path)                                             │  │
│  │                                                           │  │
│  │  Private:                                                 │  │
│  │  - connection() - Faraday with auth headers              │  │
│  │  - handle_faraday_error()                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Faraday (HTTP Client)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Authorization: Bearer <token>                            │  │
│  │  Content-Type: application/json                           │  │
│  │  Accept: application/json                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Zai API                                   │
│  sandbox.au-0000.api.assemblypay.com/webhooks                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP Response
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Response (Wrapper)                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  status         - HTTP status code                        │  │
│  │  body           - Raw response body                       │  │
│  │  headers        - Response headers                        │  │
│  │  data()         - Extracted data                          │  │
│  │  meta()         - Pagination metadata                     │  │
│  │  success?()     - 2xx status check                        │  │
│  │  client_error?()- 4xx status check                        │  │
│  │  server_error?()- 5xx status check                        │  │
│  │                                                           │  │
│  │  Private:                                                 │  │
│  │  - check_for_errors!() - Raises specific errors          │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Error Hierarchy                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Error (Base)                                             │  │
│  │    ├── AuthError                                          │  │
│  │    ├── ConfigurationError                                 │  │
│  │    ├── ApiError                                           │  │
│  │    │     ├── BadRequestError (400)                        │  │
│  │    │     ├── UnauthorizedError (401)                      │  │
│  │    │     ├── ForbiddenError (403)                         │  │
│  │    │     ├── NotFoundError (404)                          │  │
│  │    │     ├── ValidationError (422)                        │  │
│  │    │     ├── RateLimitError (429)                         │  │
│  │    │     └── ServerError (5xx)                            │  │
│  │    ├── TimeoutError                                       │  │
│  │    └── ConnectionError                                    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Request Flow

1. **Client calls** `ZaiPayment.webhooks.list()`
2. **Module** returns singleton `Resources::Webhook` instance
3. **Webhook resource** validates input and calls `client.get('/webhooks', params: {...})`
4. **Client** prepares HTTP request with authentication
5. **TokenProvider** provides valid bearer token (auto-refresh if expired)
6. **Faraday** makes HTTP request to Zai API
7. **Response** wraps Faraday response
8. **Response** checks status and raises error if needed
9. **Response** returns to client with `data()` and `meta()` methods
10. **Client application** receives response and processes data

## Key Design Decisions

### 1. Singleton Pattern for Resources
```ruby
ZaiPayment.webhooks  # Always returns same instance
```
- Reduces object creation overhead
- Consistent configuration across application
- Easy to use in any context

### 2. Dependency Injection
```ruby
Webhook.new(client: custom_client)
```
- Testable (can inject mock client)
- Flexible (can use different configs)
- Follows SOLID principles

### 3. Response Wrapper
```ruby
response = webhooks.list
response.success?  # Boolean check
response.data      # Extracted data
response.meta      # Pagination info
```
- Consistent interface across all resources
- Rich API for checking status
- Automatic error handling

### 4. Fail Fast Validation
```ruby
validate_url!(url)  # Before API call
```
- Catches errors early
- Better error messages
- Reduces unnecessary API calls

### 5. Resource-Based Organization
```ruby
lib/zai_payment/resources/
  ├── webhook.rb
  ├── user.rb      # Future
  └── item.rb      # Future
```
- Easy to extend
- Clear separation of concerns
- Follows REST principles

## Thread Safety

- ✅ **TokenProvider**: Uses Mutex for thread-safe token refresh
- ✅ **MemoryStore**: Thread-safe token storage
- ✅ **Client**: Creates new Faraday connection per instance
- ✅ **Webhook**: Stateless, no shared mutable state

## Extension Points

Add new resources by following the same pattern:

```ruby
# lib/zai_payment/resources/user.rb
module ZaiPayment
  module Resources
    class User
      def initialize(client: nil)
        @client = client || Client.new
      end
      
      def list
        client.get('/users')
      end
      
      def show(user_id)
        client.get("/users/#{user_id}")
      end
    end
  end
end

# lib/zai_payment.rb
def users
  @users ||= Resources::User.new
end
```

