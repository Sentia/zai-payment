# frozen_string_literal: true

module ZaiPayment
  module Resources
    # User resource for managing Zai users (payin and payout)
    #
    # @see https://developer.hellozai.com/docs/onboarding-a-payin-user
    # @see https://developer.hellozai.com/docs/onboarding-a-payout-user
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
        user_type: :user_type,
        device_id: :device_id,
        ip_address: :ip_address
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # List all users
      #
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing users array
      #
      # @example
      #   users = ZaiPayment::Resources::User.new
      #   response = users.list
      #   response.data # => [{"id" => "...", "email" => "..."}, ...]
      #
      # @see https://developer.hellozai.com/reference/getallusers
      def list(limit: 10, offset: 0)
        params = {
          limit: limit,
          offset: offset
        }

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
      # @option attributes [String] :email (Required) user's email address
      # @option attributes [String] :first_name (Required) user's first name
      # @option attributes [String] :last_name (Required) user's last name
      # @option attributes [String] :country (Required) user's country code (ISO 3166-1 alpha-3)
      # @option attributes [String] :user_type Optional user type ('payin' or 'payout')
      # @option attributes [String] :mobile user's mobile phone number
      # @option attributes [String] :phone user's phone number
      # @option attributes [String] :address_line1 user's address line 1
      # @option attributes [String] :address_line2 user's address line 2
      # @option attributes [String] :city user's city
      # @option attributes [String] :state user's state
      # @option attributes [String] :zip user's postal/zip code
      # @option attributes [String] :dob user's date of birth (YYYYMMDD)
      # @option attributes [String] :government_number user's government ID number
      # @option attributes [String] :device_id device ID for fraud prevention
      # @option attributes [String] :ip_address IP address for fraud prevention
      # @return [Response] the API response containing created user
      #
      # @example Create a payin user (buyer) with auto-generated ID
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
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
      #
      # @example Create a payin user with custom ID
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     id: "buyer-#{your_user_id}",
      #     email: "buyer@example.com",
      #     first_name: "John",
      #     last_name: "Doe",
      #     country: "USA"
      #   )
      #
      # @example Create a payout user (seller/merchant)
      #   users = ZaiPayment::Resources::User.new
      #   response = users.create(
      #     email: "seller@example.com",
      #     first_name: "Jane",
      #     last_name: "Smith",
      #     country: "AUS",
      #     dob: "19900101",
      #     address_line1: "456 Market St",
      #     city: "Sydney",
      #     state: "NSW",
      #     zip: "2000",
      #     mobile: "+61412345678"
      #   )
      #
      # @see https://developer.hellozai.com/reference/createuser
      # @see https://developer.hellozai.com/docs/onboarding-a-payin-user
      # @see https://developer.hellozai.com/docs/onboarding-a-payout-user
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
      # @option attributes [String] :mobile user's mobile phone number
      # @option attributes [String] :phone user's phone number
      # @option attributes [String] :address_line1 user's address line 1
      # @option attributes [String] :address_line2 user's address line 2
      # @option attributes [String] :city user's city
      # @option attributes [String] :state user's state
      # @option attributes [String] :zip user's postal/zip code
      # @option attributes [String] :dob user's date of birth (YYYYMMDD)
      # @option attributes [String] :government_number user's government ID number
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

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_presence!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_create_attributes!(attributes)
        validate_required_attributes!(attributes)
        validate_user_type!(attributes[:user_type]) if attributes[:user_type]
        validate_email!(attributes[:email])
        validate_country!(attributes[:country])
        validate_dob!(attributes[:dob]) if attributes[:dob]
        validate_user_id!(attributes[:id]) if attributes[:id]
      end

      def validate_required_attributes!(attributes)
        required_fields = %i[email first_name last_name country]

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
        # Date of birth should be in YYYYMMDD format
        return if dob.to_s.match?(/\A\d{8}\z/)

        raise Errors::ValidationError, 'dob must be in YYYYMMDD format (e.g., 19900101)'
      end

      def validate_user_id!(user_id)
        # User ID cannot contain '.' character
        raise Errors::ValidationError, "id cannot contain '.' character" if user_id.to_s.include?('.')

        # Check if empty
        return unless user_id.nil? || user_id.to_s.strip.empty?

        raise Errors::ValidationError, 'id cannot be blank if provided'
      end

      def build_user_body(attributes)
        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = FIELD_MAPPING[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
