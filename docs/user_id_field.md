# User ID Field in Zai Payment API

## Summary

The `id` field in Zai's Create User API is **optional** in practice, despite being marked as "required" in some documentation.

## How It Works

### Option 1: Auto-Generated ID (Default) ✅ **Recommended**

**Don't provide an `id` field** - Zai will automatically generate one:

```ruby
# Zai will generate an ID like "user-1556506027"
response = ZaiPayment.users.create(
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)

user_id = response.data['id']  # => "user-1556506027" (auto-generated)
```

### Option 2: Custom ID

**Provide your own `id`** to map to your existing system:

```ruby
# Use your own ID
response = ZaiPayment.users.create(
  id: "buyer-#{your_database_user_id}",  # Your custom ID
  email: 'buyer@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA'
)

user_id = response.data['id']  # => "buyer-123" (your custom ID)
```

## ID Validation Rules

If you provide a custom ID, it must:

1. ✅ **Not contain the `.` (dot) character**
2. ✅ **Not be blank/empty**
3. ✅ **Be unique** across all your users

### Valid IDs:
```ruby
✅ "user-123"
✅ "buyer_456"
✅ "seller-abc-xyz"
✅ "merchant:789"
```

### Invalid IDs:
```ruby
❌ "user.123"      # Contains dot character
❌ "   "           # Blank/empty
❌ ""              # Empty string
```

## Use Cases

### When to Use Auto-Generated IDs

Use Zai's auto-generated IDs when:
- You're building a new system without existing user IDs
- You want simplicity and don't need ID mapping
- You're prototyping or testing

**Example:**
```ruby
response = ZaiPayment.users.create(
  email: 'user@example.com',
  first_name: 'Alice',
  last_name: 'Smith',
  country: 'USA'
)

# Store Zai's generated ID in your database
your_user.update(zai_user_id: response.data['id'])
```

### When to Use Custom IDs

Use custom IDs when:
- You have existing user IDs in your system
- You want to easily map between your database and Zai
- You need predictable ID formats for integration

**Example:**
```ruby
# Your Rails user has ID 123
response = ZaiPayment.users.create(
  id: "user-#{current_user.id}",  # "user-123"
  email: current_user.email,
  first_name: current_user.first_name,
  last_name: current_user.last_name,
  country: current_user.country_code
)

# Easy to find later: just use "user-#{user.id}"
```

## Complete Examples

### Example 1: Simple Auto-Generated ID

```ruby
# Let Zai generate the ID
response = ZaiPayment.users.create(
  email: 'simple@example.com',
  first_name: 'Bob',
  last_name: 'Builder',
  country: 'AUS'
)

puts "Created user: #{response.data['id']}"
# => "Created user: user-1698765432"
```

### Example 2: Custom ID with Your Database

```ruby
# In your Rails model
class User < ApplicationRecord
  after_create :create_zai_user

  private

  def create_zai_user
    response = ZaiPayment.users.create(
      id: "platform-user-#{id}",  # Use your DB ID
      email: email,
      first_name: first_name,
      last_name: last_name,
      country: country_code
    )

    # Store for reference (though you can reconstruct it)
    update_column(:zai_user_id, response.data['id'])
  end

  def zai_user_id_computed
    "platform-user-#{id}"
  end
end
```

### Example 3: UUID-Based Custom IDs

```ruby
# Using UUIDs from your system
user_uuid = SecureRandom.uuid

response = ZaiPayment.users.create(
  id: "user-#{user_uuid}",
  email: 'uuid@example.com',
  first_name: 'Charlie',
  last_name: 'UUID',
  country: 'USA'
)

puts response.data['id']
# => "user-550e8400-e29b-41d4-a716-446655440000"
```

## Error Handling

### Invalid ID with Dot Character

```ruby
begin
  ZaiPayment.users.create(
    id: 'user.123',  # Invalid - contains dot
    email: 'test@example.com',
    first_name: 'Test',
    last_name: 'User',
    country: 'USA'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "id cannot contain '.' character"
end
```

### Blank ID

```ruby
begin
  ZaiPayment.users.create(
    id: '   ',  # Invalid - blank
    email: 'test@example.com',
    first_name: 'Test',
    last_name: 'User',
    country: 'USA'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts e.message
  # => "id cannot be blank if provided"
end
```

### Duplicate ID

```ruby
# First user
ZaiPayment.users.create(
  id: 'duplicate-123',
  email: 'first@example.com',
  first_name: 'First',
  last_name: 'User',
  country: 'USA'
)

# Second user with same ID
begin
  ZaiPayment.users.create(
    id: 'duplicate-123',  # Same ID
    email: 'second@example.com',
    first_name: 'Second',
    last_name: 'User',
    country: 'USA'
  )
rescue ZaiPayment::Errors::ValidationError => e
  puts "Duplicate ID error from Zai API"
end
```

## Best Practices

### ✅ DO:

1. **Use auto-generated IDs for simplicity** - Let Zai handle it
2. **Use custom IDs with clear prefixes** - e.g., `buyer-123`, `seller-456`
3. **Store the generated ID** in your database for reference
4. **Use consistent ID patterns** across your application

### ❌ DON'T:

1. **Don't use dots in custom IDs** - Use hyphens or underscores instead
2. **Don't reuse IDs** - Each user must have a unique ID
3. **Don't use special characters** that might cause issues
4. **Don't rely solely on custom IDs** - Always store what Zai returns

## Migration Strategy

If you're migrating from auto-generated to custom IDs (or vice versa):

```ruby
# You can't change a user's ID after creation
# Instead, you'll need to:

# 1. Create new users with custom IDs
new_response = ZaiPayment.users.create(
  id: "migrated-user-#{old_user.id}",
  email: old_user.email,
  # ... other attributes
)

# 2. Update your database records
old_user.update(zai_user_id: new_response.data['id'])

# 3. Migrate any related data (transactions, etc.)
```

## References

- [Zai Developer Documentation](https://developer.hellozai.com/docs/onboarding-a-pay-in-user)
- [Zai API Reference](https://developer.hellozai.com/reference/createuser)
- [User Management Guide](USERS.md)

## Summary

**The `id` field is OPTIONAL:**

- ✅ **Don't provide it** → Zai auto-generates (simplest)
- ✅ **Provide it** → Use your own custom ID (for mapping)

Choose based on your use case. When in doubt, **let Zai generate the ID** - it's simpler and works perfectly! 🎉

