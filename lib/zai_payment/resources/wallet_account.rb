# frozen_string_literal: true

module ZaiPayment
  module Resources
    # WalletAccount resource for managing Zai wallet accounts
    #
    # @see https://developer.hellozai.com/reference
    class WalletAccount
      attr_reader :client

      # Map of attribute keys to API field names for pay_bill
      PAY_BILL_FIELD_MAPPING = {
        account_id: :account_id,
        amount: :amount,
        reference_id: :reference_id
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # Get the user associated with a Wallet Account
      #
      # Show the User the Wallet Account is associated with using a given wallet_account_id.
      #
      # @param wallet_account_id [String] the wallet account ID
      # @return [Response] the API response containing user details
      #
      # @example
      #   wallet_accounts = ZaiPayment::Resources::WalletAccount.new
      #   response = wallet_accounts.show_user("wallet_account_id")
      #   response.data # => {"id" => "user_id", "full_name" => "Samuel Seller", ...}
      #
      # @see https://developer.hellozai.com/reference
      def show_user(wallet_account_id)
        validate_id!(wallet_account_id, 'wallet_account_id')
        client.get("/wallet_accounts/#{wallet_account_id}/users")
      end

      # Pay a bill by withdrawing funds from a Wallet Account to a specified BPay account
      #
      # @param wallet_account_id [String] the wallet account ID
      # @param attributes [Hash] bill payment attributes
      # @option attributes [String] :account_id (Required) BPay account ID to withdraw to
      # @option attributes [Integer] :amount (Required) Amount in cents to withdraw
      # @option attributes [String] :reference_id Optional unique reference information
      # @return [Response] the API response containing disbursement details
      #
      # @example Pay a bill
      #   wallet_accounts = ZaiPayment::Resources::WalletAccount.new
      #   response = wallet_accounts.pay_bill(
      #     '901d8cd0-6af3-0138-967d-0a58a9feac04',
      #     account_id: 'c1824ad0-73f1-0138-3700-0a58a9feac09',
      #     amount: 173,
      #     reference_id: 'test100'
      #   )
      #
      # @see https://developer.hellozai.com/reference
      def pay_bill(wallet_account_id, **attributes)
        validate_id!(wallet_account_id, 'wallet_account_id')
        validate_pay_bill_attributes!(attributes)

        body = build_pay_bill_body(attributes)
        client.post("/wallet_accounts/#{wallet_account_id}/bill_payment", body: body)
      end

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_pay_bill_attributes!(attributes)
        validate_required_pay_bill_attributes!(attributes)
        validate_amount!(attributes[:amount]) if attributes[:amount]
        validate_reference_id!(attributes[:reference_id]) if attributes[:reference_id]
      end

      def validate_required_pay_bill_attributes!(attributes)
        required_fields = %i[account_id amount]

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || (attributes[field].respond_to?(:to_s) && attributes[field].to_s.strip.empty?)
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_amount!(amount)
        # Amount must be a positive integer
        return if amount.is_a?(Integer) && amount.positive?

        raise Errors::ValidationError, 'amount must be a positive integer'
      end

      def validate_reference_id!(reference_id)
        # Reference ID cannot contain single quote character
        return unless reference_id.to_s.include?("'")

        raise Errors::ValidationError, "reference_id cannot contain single quote (') character"
      end

      def build_pay_bill_body(attributes)
        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = PAY_BILL_FIELD_MAPPING[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
