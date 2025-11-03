# frozen_string_literal: true

module ZaiPayment
  module Resources
    # BankAccount resource for managing Zai bank accounts
    #
    # @see https://developer.hellozai.com/reference/createbankaccount
    class BankAccount
      attr_reader :client

      # Map of attribute keys to API field names
      FIELD_MAPPING = {
        user_id: :user_id,
        bank_name: :bank_name,
        account_name: :account_name,
        routing_number: :routing_number,
        account_number: :account_number,
        account_type: :account_type,
        holder_type: :holder_type,
        country: :country,
        payout_currency: :payout_currency,
        currency: :currency
      }.freeze

      # Map of UK-specific attribute keys to API field names
      UK_FIELD_MAPPING = {
        user_id: :user_id,
        bank_name: :bank_name,
        account_name: :account_name,
        routing_number: :routing_number,
        account_number: :account_number,
        account_type: :account_type,
        holder_type: :holder_type,
        country: :country,
        payout_currency: :payout_currency,
        currency: :currency,
        iban: :iban,
        swift_code: :swift_code
      }.freeze

      # Valid account types
      VALID_ACCOUNT_TYPES = %w[savings checking].freeze

      # Valid holder types
      VALID_HOLDER_TYPES = %w[personal business].freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # Get a specific bank account by ID
      #
      # @param bank_account_id [String] the bank account ID
      # @param include_decrypted_fields [Boolean] if true, the API will decrypt and return
      #   sensitive bank account fields (for example, the full account number). Defaults to false
      # @return [Response] the API response containing bank account details
      #
      # @example
      #   bank_accounts = ZaiPayment::Resources::BankAccount.new
      #   response = bank_accounts.show("bank_account_id")
      #   response.data # => {"id" => "bank_account_id", "active" => true, ...}
      #
      # @example with decrypted fields
      #   response = bank_accounts.show("bank_account_id", include_decrypted_fields: true)
      #   # Returns full account number instead of masked version
      #
      # @see https://developer.hellozai.com/reference/showbankaccount
      def show(bank_account_id, include_decrypted_fields: false)
        validate_id!(bank_account_id, 'bank_account_id')

        params = {}
        params[:include_decrypted_fields] = include_decrypted_fields if include_decrypted_fields

        client.get("/bank_accounts/#{bank_account_id}", params: params)
      end

      # Create a new bank account for Australia
      #
      # @param attributes [Hash] bank account attributes
      # @option attributes [String] :user_id (Required) User ID
      # @option attributes [String] :bank_name (Required) Bank name (defaults to Bank of Australia)
      # @option attributes [String] :account_name (Required) Account name (defaults to Samuel Seller)
      # @option attributes [String] :routing_number (Required) Routing number / BSB number
      #   (defaults to 111123)
      # @option attributes [String] :account_number (Required) Account number
      #   (defaults to 111234)
      # @option attributes [String] :account_type (Required) Account type
      #   ('savings' or 'checking', defaults to checking)
      # @option attributes [String] :holder_type (Required) Holder type ('personal' or 'business', defaults to personal)
      # @option attributes [String] :country (Required) Country code (ISO 3166-1 alpha-3, max 3 chars, defaults to AUS)
      # @option attributes [String] :payout_currency Optional currency code for payouts (ISO 4217 alpha-3)
      # @option attributes [String] :currency Optional currency code (ISO 4217 alpha-3)
      # @return [Response] the API response containing created bank account
      #
      # @example Create an Australian bank account
      #   bank_accounts = ZaiPayment::Resources::BankAccount.new
      #   response = bank_accounts.create_au(
      #     user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      #     bank_name: 'Bank of Australia',
      #     account_name: 'Samuel Seller',
      #     routing_number: '111123',
      #     account_number: '111234',
      #     account_type: 'checking',
      #     holder_type: 'personal',
      #     country: 'AUS',
      #     payout_currency: 'AUD',
      #     currency: 'AUD'
      #   )
      #
      # @see https://developer.hellozai.com/reference/createbankaccount
      def create_au(**attributes)
        validate_create_au_attributes!(attributes)

        body = build_bank_account_body(attributes, :au)
        client.post('/bank_accounts', body: body)
      end

      # Create a new bank account for UK
      #
      # @param attributes [Hash] bank account attributes
      # @option attributes [String] :user_id (Required) User ID
      # @option attributes [String] :bank_name (Required) Bank name (defaults to Bank of UK)
      # @option attributes [String] :account_name (Required) Account name (defaults to Samuel Seller)
      # @option attributes [String] :routing_number (Required) Routing number / Sort Code / BSB
      #   number (defaults to 111123)
      # @option attributes [String] :account_number (Required) Account number
      #   (defaults to 111234)
      # @option attributes [String] :account_type (Required) Account type
      #   ('savings' or 'checking', defaults to checking)
      # @option attributes [String] :holder_type (Required) Holder type ('personal' or 'business', defaults to personal)
      # @option attributes [String] :country (Required) Country code (ISO 3166-1 alpha-3, max 3 chars, defaults to GBR)
      # @option attributes [String] :payout_currency Optional currency code for payouts (ISO 4217 alpha-3)
      # @option attributes [String] :currency Optional currency code (ISO 4217 alpha-3)
      # @option attributes [String] :iban (Required for UK) IBAN number
      # @option attributes [String] :swift_code (Required for UK) SWIFT Code / BIC
      # @return [Response] the API response containing created bank account
      #
      # @example Create a UK bank account
      #   bank_accounts = ZaiPayment::Resources::BankAccount.new
      #   response = bank_accounts.create_uk(
      #     user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      #     bank_name: 'Bank of UK',
      #     account_name: 'Samuel Seller',
      #     routing_number: '111123',
      #     account_number: '111234',
      #     account_type: 'checking',
      #     holder_type: 'personal',
      #     country: 'GBR',
      #     payout_currency: 'GBP',
      #     currency: 'GBP',
      #     iban: 'GB25QHWM02498765432109',
      #     swift_code: 'BUKBGB22'
      #   )
      #
      # @see https://developer.hellozai.com/reference/createbankaccount
      def create_uk(**attributes)
        validate_create_uk_attributes!(attributes)

        body = build_bank_account_body(attributes, :uk)
        client.post('/bank_accounts', body: body)
      end

      # Redact a bank account
      #
      # Redacts a bank account using the given bank_account_id. Redacted bank accounts
      # can no longer be used as a funding source or a disbursement destination.
      #
      # @param bank_account_id [String] the bank account ID
      # @return [Response] the API response
      #
      # @example
      #   bank_accounts = ZaiPayment::Resources::BankAccount.new
      #   response = bank_accounts.redact("bank_account_id")
      #
      # @see https://developer.hellozai.com/reference/redactbankaccount
      def redact(bank_account_id)
        validate_id!(bank_account_id, 'bank_account_id')
        client.delete("/bank_accounts/#{bank_account_id}")
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

      def validate_create_au_attributes!(attributes)
        validate_required_au_attributes!(attributes)
        validate_account_type!(attributes[:account_type]) if attributes[:account_type]
        validate_holder_type!(attributes[:holder_type]) if attributes[:holder_type]
        validate_country!(attributes[:country]) if attributes[:country]
      end

      def validate_create_uk_attributes!(attributes)
        validate_required_uk_attributes!(attributes)
        validate_account_type!(attributes[:account_type]) if attributes[:account_type]
        validate_holder_type!(attributes[:holder_type]) if attributes[:holder_type]
        validate_country!(attributes[:country]) if attributes[:country]
      end

      def validate_required_au_attributes!(attributes)
        required_fields = %i[user_id bank_name account_name routing_number account_number
                             account_type holder_type country]

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || attributes[field].to_s.strip.empty?
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_required_uk_attributes!(attributes)
        required_fields = %i[user_id bank_name account_name routing_number account_number
                             account_type holder_type country iban swift_code]

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || attributes[field].to_s.strip.empty?
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_account_type!(account_type)
        return if VALID_ACCOUNT_TYPES.include?(account_type.to_s.downcase)

        raise Errors::ValidationError,
              "account_type must be one of: #{VALID_ACCOUNT_TYPES.join(', ')}"
      end

      def validate_holder_type!(holder_type)
        return if VALID_HOLDER_TYPES.include?(holder_type.to_s.downcase)

        raise Errors::ValidationError,
              "holder_type must be one of: #{VALID_HOLDER_TYPES.join(', ')}"
      end

      def validate_country!(country)
        # Country should be ISO 3166-1 alpha-3 code (3 letters)
        return if country.to_s.match?(/\A[A-Z]{3}\z/i) && country.to_s.length <= 3

        raise Errors::ValidationError, 'country must be a valid ISO 3166-1 alpha-3 code (e.g., AUS, GBR)'
      end

      def build_bank_account_body(attributes, region)
        body = {}
        field_mapping = region == :uk ? UK_FIELD_MAPPING : FIELD_MAPPING

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = field_mapping[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
