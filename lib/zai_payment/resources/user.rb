# frozen_string_literal: true

module ZaiPayment
  module Resources
    # User resource for managing Zai users (payin and payout)
    #
    # @see https://developer.hellozai.com/docs/onboarding-a-pay-in-user
    # @see https://developer.hellozai.com/docs/onboarding-a-pay-out-user
    class User
      attr_reader :client

      # User types
      USER_TYPE_PAYIN = 'payin'
      USER_TYPE_PAYOUT = 'payout'

      # Valid user types
      VALID_USER_TYPES = [USER_TYPE_PAYIN, USER_TYPE_PAYOUT].freeze

      # Map of attribute keys to API field names
      FIELD_MAPPING = {
        id: :id,
        email: :email,
        first_name: :first_name,
        last_name: :last_name,
        mobile: :mobile,
        phone: :phone,
        address_line1: :address_line1,
        address_line2: :address_line2,
        city: :city,
        state: :state,
        zip: :zip,
        country: :country,
        dob: :dob,
        government_number: :government_number,
        drivers_license_number: :drivers_license_number,
        drivers_license_state: :drivers_license_state,
        logo_url: :logo_url,
        color_1: :color_1,
        color_2: :color_2,
        custom_descriptor: :custom_descriptor,
        authorized_signer_title: :authorized_signer_title,
        user_type: :user_type,
        device_id: :device_id,
        ip_address: :ip_address
      }.freeze

      # Map of company attribute keys to API field names
      COMPANY_FIELD_MAPPING = {
        name: :name,
        legal_name: :legal_name,
        tax_number: :tax_number,
        business_email: :business_email,
        charge_tax: :charge_tax,
        address_line1: :address_line1,
        address_line2: :address_line2,
        city: :city,
        state: :state,
        zip: :zip,
        country: :country,
        phone: :phone
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # List all users
      #
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @param search [String] text value to be used for searching users
      # @return [Response] the API response containing users array
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.list
      #   response.data # => [{"id" => "...", "email" => "..."}, ...]
      #
      # @example with search
      #   response = users.list(search: "john@example.com")
      #
      # @see https://developer.hellozai.com/reference/getallusers
      def list(limit: 10, offset: 0, search: nil)
        params = {
          limit: limit,
          offset: offset
        }
        params[:search] = search if search

        client.get('/users', params: params)
      end

      # Get a specific user by ID
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response containing user details
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.show("user_id")
      #   response.data # => {"id" => "user_id", "email" => "...", ...}
      #
      # @see https://developer.hellozai.com/reference/getuserbyid
      def show(user_id)
        validate_id!(user_id, 'user_id')
        client.get("/users/#{user_id}")
      end

      # Create a new user (payin or payout)
      #
      # @param attributes [Hash] user attributes
      # @option attributes [String] :id Optional unique ID for the user. If not provided,
      #   Zai will generate one automatically. Cannot contain '.' character.
      #   Useful for mapping to your existing system's user IDs.
      # @option attributes [String] :user_type (Required) User type ('payin' or 'payout').
      #   This determines which fields are required.
      # @option attributes [String] :email (Required) user's email address
      # @option attributes [String] :first_name (Required) user's first name
      # @option attributes [String] :last_name (Required) user's last name
      # @option attributes [String] :country (Required) user's country code (ISO 3166-1 alpha-3)
      # @option attributes [String] :address_line1 (Required for payout) user's address line 1
      # @option attributes [String] :city (Required for payout) user's city
      # @option attributes [String] :state (Required for payout) user's state
      # @option attributes [String] :zip (Required for payout) user's postal/zip code
      # @option attributes [String] :dob (Required for payout) user's date of birth (DD/MM/YYYY)
      # @option attributes [String] :device_id device ID for fraud prevention (required when charging card)
      # @option attributes [String] :ip_address IP address for fraud prevention (required when charging card)
      # @option attributes [String] :address_line2 user's address line 2
      # @option attributes [String] :mobile user's mobile phone number (international format with '+')
      # @option attributes [String] :phone user's phone number
      # @option attributes [String] :government_number user's government ID number (SSN, TFN, etc.)
      # @option attributes [String] :drivers_license_number driving license number
      # @option attributes [String] :drivers_license_state state section of the user's driving license
      # @option attributes [String] :logo_url URL link to the logo
      # @option attributes [String] :color_1 color code number 1
      # @option attributes [String] :color_2 color code number 2
      # @option attributes [String] :custom_descriptor custom descriptor for bundle direct debit statements
      # @option attributes [String] :authorized_signer_title job title for AMEX merchants (e.g., Director)
      # @option attributes [Hash] :company company details (creates a company for the user)
      # @return [Response] the API response containing created user
      #
      # @example Create a payin user (buyer) with auto-generated ID
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     user_type: "payin",
      #     email: "buyer@example.com",
      #     first_name: "John",
      #     last_name: "Doe",
      #     country: "USA",
      #     mobile: "+1234567890",
      #     address_line1: "123 Main St",
      #     city: "New York",
      #     state: "NY",
      #     zip: "10001"
      #   )
      #   # Note: device_id and ip_address are not required at user creation,
      #   # but will be required when creating an item and charging a card
      #
      # @example Create a payin user with custom ID
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     id: "buyer-#{your_user_id}",
      #     user_type: "payin",
      #     email: "buyer@example.com",
      #     first_name: "John",
      #     last_name: "Doe",
      #     country: "USA"
      #   )
      #
      # @example Create a payout user (seller/merchant) - individual
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     user_type: "payout",
      #     email: "seller@example.com",
      #     first_name: "Jane",
      #     last_name: "Smith",
      #     country: "AUS",
      #     dob: "01/01/1990",
      #     address_line1: "456 Market St",
      #     city: "Sydney",
      #     state: "NSW",
      #     zip: "2000",
      #     mobile: "+61412345678"
      #   )
      #
      # @example Create a payout user with company details
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     user_type: "payout",
      #     email: "business@example.com",
      #     first_name: "John",
      #     last_name: "Doe",
      #     country: "AUS",
      #     dob: "15/06/1985",
      #     address_line1: "789 Business Ave",
      #     city: "Melbourne",
      #     state: "VIC",
      #     zip: "3000",
      #     mobile: "+61412345678",
      #     authorized_signer_title: "Director",
      #     company: {
      #       name: "ABC Company",
      #       legal_name: "ABC Pty Ltd",
      #       tax_number: "123456789",
      #       business_email: "admin@abc.com",
      #       address_line1: "123 Business St",
      #       city: "Melbourne",
      #       state: "VIC",
      #       zip: "3000",
      #       phone: "+61398765432",
      #       country: "AUS"
      #     }
      #   )
      #
      # @see https://developer.hellozai.com/reference/createuser
      # @see https://developer.hellozai.com/docs/onboarding-a-pay-in-user
      # @see https://developer.hellozai.com/docs/onboarding-a-pay-out-user
      def create(**attributes)
        validate_create_attributes!(attributes)

        body = build_user_body(attributes)
        client.post('/users', body: body)
      end

      # Update an existing user
      #
      # @param user_id [String] the user ID
      # @param attributes [Hash] user attributes to update
      # @option attributes [String] :email user's email address
      # @option attributes [String] :first_name user's first name
      # @option attributes [String] :last_name user's last name
      # @option attributes [String] :mobile user's mobile phone number (international format with '+')
      # @option attributes [String] :phone user's phone number
      # @option attributes [String] :address_line1 user's address line 1
      # @option attributes [String] :address_line2 user's address line 2
      # @option attributes [String] :city user's city
      # @option attributes [String] :state user's state
      # @option attributes [String] :zip user's postal/zip code
      # @option attributes [String] :dob user's date of birth (DD/MM/YYYY)
      # @option attributes [String] :government_number user's government ID number (SSN, TFN, etc.)
      # @option attributes [String] :drivers_license_number driving license number
      # @option attributes [String] :drivers_license_state state section of the user's driving license
      # @option attributes [String] :logo_url URL link to the logo
      # @option attributes [String] :color_1 color code number 1
      # @option attributes [String] :color_2 color code number 2
      # @option attributes [String] :custom_descriptor custom descriptor for bundle direct debit statements
      # @option attributes [String] :authorized_signer_title job title for AMEX merchants (e.g., Director)
      # @return [Response] the API response containing updated user
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.update(
      #     "user_id",
      #     mobile: "+1234567890",
      #     address_line1: "789 New St"
      #   )
      #
      # @see https://developer.hellozai.com/reference/updateuser
      def update(user_id, **attributes)
        validate_id!(user_id, 'user_id')

        body = build_user_body(attributes)

        validate_email!(attributes[:email]) if attributes[:email]
        validate_dob!(attributes[:dob]) if attributes[:dob]

        raise Errors::ValidationError, 'At least one attribute must be provided for update' if body.empty?

        client.patch("/users/#{user_id}", body: body)
      end

      # Show the user's wallet account
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response containing wallet account details
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.wallet_account("user_id")
      #   response.data # => {"id" => "...", "balance" => ..., ...}
      #
      # @see https://developer.hellozai.com/reference/showuserwalletaccounts
      def wallet_account(user_id)
        validate_id!(user_id, 'user_id')
        client.get("/users/#{user_id}/wallet_accounts")
      end

      # List items associated with the user
      #
      # @param user_id [String] the user ID
      # @param limit [Integer] number of records to return (default: 10, max: 200)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing items array
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.items("user_id")
      #   response.data # => [{"id" => "...", "name" => "..."}, ...]
      #
      # @example with custom pagination
      #   response = users.items("user_id", limit: 50, offset: 10)
      #
      # @see https://developer.hellozai.com/reference/listuseritems
      def items(user_id, limit: 10, offset: 0)
        validate_id!(user_id, 'user_id')
        params = {
          limit: limit,
          offset: offset
        }

        client.get("/users/#{user_id}/items", params: params)
      end

      # Set the user's disbursement account
      #
      # @param user_id [String] the user ID
      # @param account_id [String] the bank account ID to use for disbursements
      # @return [Response] the API response
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.set_disbursement_account("user_id", "account_id")
      #
      # @see https://developer.hellozai.com/reference/setuserdisbursementaccount
      def set_disbursement_account(user_id, account_id)
        validate_id!(user_id, 'user_id')
        validate_id!(account_id, 'account_id')

        body = { account_id: account_id }
        client.patch("/users/#{user_id}/disbursement_account", body: body)
      end

      # Show the user's bank account
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response containing bank account details
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.bank_account("user_id")
      #   response.data # => {"id" => "...", "account_name" => "...", ...}
      #
      # @see https://developer.hellozai.com/reference/showuserbankaccount
      def bank_account(user_id)
        validate_id!(user_id, 'user_id')
        client.get("/users/#{user_id}/bank_accounts")
      end

      # Verify user (Prelive Only)
      # Sets a user's verification state to approved on pre-live environment
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.verify("user_id")
      #
      # @note This endpoint only works in the pre-live environment.
      #   The user verification workflow holds for all users in production.
      #
      # @see https://developer.hellozai.com/reference/verifyuser
      def verify(user_id)
        validate_id!(user_id, 'user_id')
        client.patch("/users/#{user_id}/identity_verified")
      end

      # Show the user's card account
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response containing card account details
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.card_account("user_id")
      #   response.data # => {"id" => "...", "card" => {...}, ...}
      #
      # @see https://developer.hellozai.com/reference/showusercardaccount
      def card_account(user_id)
        validate_id!(user_id, 'user_id')
        client.get("/users/#{user_id}/card_accounts")
      end

      # List BPay accounts associated with the user
      #
      # @param user_id [String] the user ID
      # @return [Response] the API response containing BPay accounts array
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.bpay_accounts("user_id")
      #   response.data # => [{"id" => "...", "biller_code" => "..."}, ...]
      #
      # @see https://developer.hellozai.com/reference/listuserbpayaccounts
      def bpay_accounts(user_id)
        validate_id!(user_id, 'user_id')
        client.get("/users/#{user_id}/bpay_accounts")
      end

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_presence!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_create_attributes!(attributes) # rubocop:disable Metrics/AbcSize
        validate_required_attributes!(attributes)
        validate_user_type!(attributes[:user_type])
        validate_email!(attributes[:email])
        validate_country!(attributes[:country])
        validate_dob!(attributes[:dob]) if attributes[:dob]
        validate_user_id!(attributes[:id]) if attributes[:id]
        validate_company!(attributes[:company], attributes[:user_type]) if attributes[:company]
      end

      def validate_required_attributes!(attributes)
        # Base required fields for all users
        required_fields = %i[email first_name last_name country user_type]

        # Additional required fields for payout users
        user_type = attributes[:user_type]&.to_s&.downcase
        if user_type == USER_TYPE_PAYOUT
          # For payout users, these fields become required
          required_fields += %i[address_line1 city state zip dob]
        end

        # NOTE: device_id and ip_address are NOT required at user creation for payin users.
        # They are only required later when an item is created and a card is charged.

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || attributes[field].to_s.strip.empty?
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_user_type!(user_type)
        return if VALID_USER_TYPES.include?(user_type.to_s.downcase)

        raise Errors::ValidationError,
              "user_type must be one of: #{VALID_USER_TYPES.join(', ')}"
      end

      def validate_email!(email)
        # Basic email format validation
        email_regex = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
        return if email&.match?(email_regex)

        raise Errors::ValidationError, 'email must be a valid email address'
      end

      def validate_country!(country)
        # Country should be ISO 3166-1 alpha-3 code (3 letters)
        return if country.to_s.match?(/\A[A-Z]{3}\z/i)

        raise Errors::ValidationError, 'country must be a valid ISO 3166-1 alpha-3 code (e.g., USA, AUS, GBR)'
      end

      def validate_dob!(dob)
        # Date of birth should be in DD/MM/YYYY format
        return if dob.to_s.match?(%r{\A\d{2}/\d{2}/\d{4}\z})

        raise Errors::ValidationError, 'dob must be in DD/MM/YYYY format (e.g., 15/01/1990)'
      end

      def validate_user_id!(user_id)
        # User ID cannot contain '.' character
        raise Errors::ValidationError, "id cannot contain '.' character" if user_id.to_s.include?('.')

        # Check if empty
        return unless user_id.nil? || user_id.to_s.strip.empty?

        raise Errors::ValidationError, 'id cannot be blank if provided'
      end

      def validate_company!(company, user_type = nil)
        return unless company.is_a?(Hash)

        required_fields = required_company_fields(user_type)
        missing_fields = find_missing_company_fields(company, required_fields)

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Company is missing required fields: #{missing_fields.join(', ')}"
      end

      def required_company_fields(user_type)
        base_fields = %i[name legal_name tax_number business_email]
        additional_fields = payout_company?(user_type) ? payout_company_fields : %i[country]
        base_fields + additional_fields
      end

      def payout_company?(user_type)
        user_type&.to_s&.downcase == USER_TYPE_PAYOUT
      end

      def payout_company_fields
        %i[address_line1 city state zip phone country]
      end

      def find_missing_company_fields(company, required_fields)
        required_fields.select do |field|
          company[field].nil? || company[field].to_s.strip.empty?
        end
      end

      def build_user_body(attributes) # rubocop:disable Metrics/CyclomaticComplexity
        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          # Handle company object separately
          if key == :company
            body[:company] = build_company_body(value) if value.is_a?(Hash)
            next
          end

          api_field = FIELD_MAPPING[key]
          body[api_field] = value if api_field
        end

        body
      end

      def build_company_body(company_attributes)
        company = {}

        company_attributes.each do |key, value|
          # Don't skip false values for charge_tax
          next if value.nil?
          next if key != :charge_tax && value.respond_to?(:empty?) && value.empty?

          api_field = COMPANY_FIELD_MAPPING[key]
          company[api_field] = value if api_field
        end

        company
      end
    end
  end
end
