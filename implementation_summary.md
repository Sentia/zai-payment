# New User Parameters Implementation Summary

This document summarizes the new body parameters added to the User resource for creating users in the Zai Payment gem.

## Added Parameters

### Individual User Parameters

The following new parameters have been added for individual users:

1. **`drivers_license_number`** (String)
   - Driving license number of the user
   - Optional field for enhanced verification

2. **`drivers_license_state`** (String)
   - State section of the user's driving license
   - Optional field for enhanced verification

3. **`logo_url`** (String)
   - URL link to the logo
   - Optional field for merchant branding

4. **`color_1`** (String)
   - Primary color code (e.g., #FF5733)
   - Optional field for merchant branding

5. **`color_2`** (String)
   - Secondary color code (e.g., #C70039)
   - Optional field for merchant branding

6. **`custom_descriptor`** (String)
   - Custom text that appears on bank statements
   - Optional field for merchant branding
   - Shows on bundle direct debit statements, wire payouts, and PayPal statements

7. **`authorized_signer_title`** (String)
   - Job title of the authorized signer (e.g., "Director", "General Manager")
   - Required for AMEX merchants
   - Refers to the role/job title for the individual user who is authorized to sign contracts

### Company Object

A new **`company`** parameter has been added to support business users. When provided, it creates a company for the user.

#### Required Company Fields

- **`name`** (String) - Company name
- **`legal_name`** (String) - Legal business name (e.g., "ABC Pty Ltd")
- **`tax_number`** (String) - ABN/TFN/Tax number
- **`business_email`** (String) - Business email address
- **`country`** (String) - Country code (ISO 3166-1 alpha-3)

#### Optional Company Fields

- **`charge_tax`** (Boolean) - Whether to charge GST/tax (true/false)
- **`address_line1`** (String) - Business address line 1
- **`address_line2`** (String) - Business address line 2
- **`city`** (String) - Business city
- **`state`** (String) - Business state/province
- **`zip`** (String) - Business postal code
- **`phone`** (String) - Business phone number

## Implementation Details

### Code Changes

1. **Field Mappings** - Added new fields to `FIELD_MAPPING` constant
2. **Company Field Mapping** - Added new `COMPANY_FIELD_MAPPING` constant
3. **Validation** - Added `validate_company!` method to validate company required fields
4. **Body Building** - Updated `build_user_body` to handle company object separately
5. **Company Body Builder** - Added `build_company_body` method to construct company payload
6. **Documentation** - Updated all method documentation with new parameters

### Special Handling

- **Company Object**: Handled separately in `build_user_body` method
- **Boolean Values**: Special handling for `charge_tax` to preserve `false` values
- **Nested Structure**: Company fields are properly nested in the API payload

## Usage Examples

### Enhanced Verification with Driver's License

```ruby
ZaiPayment.users.create(
  email: 'user@example.com',
  first_name: 'John',
  last_name: 'Doe',
  country: 'USA',
  drivers_license_number: 'D1234567',
  drivers_license_state: 'CA',
  government_number: '123-45-6789'
)
```

### Merchant with Custom Branding

```ruby
ZaiPayment.users.create(
  email: 'merchant@example.com',
  first_name: 'Jane',
  last_name: 'Smith',
  country: 'AUS',
  logo_url: 'https://example.com/logo.png',
  color_1: '#FF5733',
  color_2: '#C70039',
  custom_descriptor: 'MY STORE'
)
```

### Business User with Company

```ruby
ZaiPayment.users.create(
  email: 'director@company.com',
  first_name: 'John',
  last_name: 'Director',
  country: 'AUS',
  mobile: '+61412345678',
  authorized_signer_title: 'Director',
  company: {
    name: 'ABC Company',
    legal_name: 'ABC Company Pty Ltd',
    tax_number: '123456789',
    business_email: 'admin@abc.com',
    country: 'AUS',
    charge_tax: true,
    address_line1: '123 Business St',
    city: 'Melbourne',
    state: 'VIC',
    zip: '3000'
  }
)
```

### AMEX Merchant Setup

```ruby
ZaiPayment.users.create(
  email: 'amex.merchant@example.com',
  first_name: 'Michael',
  last_name: 'Manager',
  country: 'AUS',
  authorized_signer_title: 'Managing Director',  # Required for AMEX
  company: {
    name: 'AMEX Shop',
    legal_name: 'AMEX Shop Pty Limited',
    tax_number: '51824753556',
    business_email: 'finance@amexshop.com',
    country: 'AUS',
    charge_tax: true
  }
)
```

## Validation

The following validations are in place:

1. **Company Validation**: When `company` is provided, all required company fields must be present
2. **Email Format**: Must be a valid email address
3. **Country Code**: Must be ISO 3166-1 alpha-3 format (3 letters)
4. **DOB Format**: Must be in DD/MM/YYYY format
5. **User ID**: Cannot contain '.' character

## Documentation Updates

The following documentation files have been updated:

1. **`lib/zai_payment/resources/user.rb`** - Implementation
2. **`examples/users.md`** - Usage examples and patterns
3. **`docs/users.md`** - Field reference and comprehensive guide
4. **`readme.md`** - Quick start example

## Testing

All new parameters have been tested and verified:
- ✓ Drivers license parameters
- ✓ Branding parameters (logo_url, colors, custom_descriptor)
- ✓ Authorized signer title
- ✓ Company object with all fields
- ✓ Company validation (required fields)
- ✓ Boolean handling (charge_tax false preservation)

## API Compatibility

These changes are **backward compatible**. All new parameters are optional and existing code will continue to work without modifications.

## Related Files

- `/lib/zai_payment/resources/user.rb` - Main implementation
- `/examples/users.md` - Usage examples
- `/docs/users.md` - Field reference
- `/readme.md` - Quick start guide

