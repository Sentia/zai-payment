# frozen_string_literal: true

module ZaiPayment
  module Resources
    # BpayAccount resource for managing Zai BPay accounts
    #
    # @see https://developer.hellozai.com/reference/createbpayaccount
    class BpayAccount
      attr_reader :client

      # Map of attribute keys to API field names
      FIELD_MAPPING = {
        user_id: :user_id,
        account_name: :account_name,
        biller_code: :biller_code,
        bpay_crn: :bpay_crn
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # Get a specific BPay account by ID
      #
      # @param bpay_account_id [String] the BPay account ID
      # @return [Response] the API response containing BPay account details
      #
      # @example
      #   bpay_accounts = ZaiPayment::Resources::BpayAccount.new
      #   response = bpay_accounts.show("bpay_account_id")
      #   response.data # => {"id" => "bpay_account_id", "active" => true, ...}
      #
      # @see https://developer.hellozai.com/reference/showbpayaccount
      def show(bpay_account_id)
        validate_id!(bpay_account_id, 'bpay_account_id')
        client.get("/bpay_accounts/#{bpay_account_id}")
      end

      # Redact a BPay account
      #
      # Redacts a BPay account using the given bpay_account_id. Redacted BPay accounts
      # can no longer be used as a disbursement destination.
      #
      # @param bpay_account_id [String] the BPay account ID
      # @return [Response] the API response
      #
      # @example
      #   bpay_accounts = ZaiPayment::Resources::BpayAccount.new
      #   response = bpay_accounts.redact("bpay_account_id")
      #
      # @see https://developer.hellozai.com/reference/redactbpayaccount
      def redact(bpay_account_id)
        validate_id!(bpay_account_id, 'bpay_account_id')
        client.delete("/bpay_accounts/#{bpay_account_id}")
      end

      # Get the user associated with a BPay account
      #
      # Show the User the BPay Account is associated with using a given bpay_account_id.
      #
      # @param bpay_account_id [String] the BPay account ID
      # @return [Response] the API response containing user details
      #
      # @example
      #   bpay_accounts = ZaiPayment::Resources::BpayAccount.new
      #   response = bpay_accounts.show_user("bpay_account_id")
      #   response.data # => {"id" => "user_id", "full_name" => "Samuel Seller", ...}
      #
      # @see https://developer.hellozai.com/reference/showbpayaccountuser
      def show_user(bpay_account_id)
        validate_id!(bpay_account_id, 'bpay_account_id')
        client.get("/bpay_accounts/#{bpay_account_id}/users")
      end

      # Create a new BPay account
      #
      # Create a BPay Account to be used as a Disbursement destination.
      #
      # @param attributes [Hash] BPay account attributes
      # @option attributes [String] :user_id (Required) User ID
      # @option attributes [String] :account_name (Required) Name assigned by the platform/marketplace
      #   to identify the account (similar to a nickname). Defaults to "My Water Bill Company"
      # @option attributes [Integer] :biller_code (Required) The Biller Code for the biller that will
      #   receive the payment. The Biller Code must be a numeric value with 3 to 10 digits.
      # @option attributes [String] :bpay_crn (Required) Customer reference number (crn) to be used for
      #   this bpay account. The CRN must contain between 2 and 20 digits. Defaults to "987654321"
      # @return [Response] the API response containing created BPay account
      #
      # @example Create a BPay account
      #   bpay_accounts = ZaiPayment::Resources::BpayAccount.new
      #   response = bpay_accounts.create(
      #     user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      #     account_name: 'My Water Bill Company',
      #     biller_code: 123456,
      #     bpay_crn: '987654321'
      #   )
      #
      # @see https://developer.hellozai.com/reference/createbpayaccount
      def create(**attributes)
        validate_create_attributes!(attributes)

        body = build_bpay_account_body(attributes)
        client.post('/bpay_accounts', body: body)
      end

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_create_attributes!(attributes)
        validate_required_attributes!(attributes)
        validate_biller_code!(attributes[:biller_code]) if attributes[:biller_code]
        validate_bpay_crn!(attributes[:bpay_crn]) if attributes[:bpay_crn]
      end

      def validate_required_attributes!(attributes)
        required_fields = %i[user_id account_name biller_code bpay_crn]

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || (attributes[field].respond_to?(:to_s) && attributes[field].to_s.strip.empty?)
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_biller_code!(biller_code)
        # Biller code must be a numeric value with 3 to 10 digits
        biller_code_str = biller_code.to_s

        return if biller_code_str.match?(/\A\d{3,10}\z/)

        raise Errors::ValidationError,
              'biller_code must be a numeric value with 3 to 10 digits'
      end

      def validate_bpay_crn!(bpay_crn)
        # CRN must contain between 2 and 20 digits
        bpay_crn_str = bpay_crn.to_s

        return if bpay_crn_str.match?(/\A\d{2,20}\z/)

        raise Errors::ValidationError,
              'bpay_crn must contain between 2 and 20 digits'
      end

      def build_bpay_account_body(attributes)
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
