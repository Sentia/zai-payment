# frozen_string_literal: true

module ZaiPayment
  module Resources
    # VirtualAccount resource for managing Zai virtual accounts
    #
    # @see https://developer.hellozai.com/reference
    class VirtualAccount
      attr_reader :client

      # Map of attribute keys to API field names for create
      CREATE_FIELD_MAPPING = {
        account_name: :account_name,
        aka_names: :aka_names
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new(base_endpoint: :va_base)
      end

      # Create a Virtual Account for a given Wallet Account
      #
      # @param wallet_account_id [String] the wallet account ID
      # @param attributes [Hash] virtual account attributes
      # @option attributes [String] :account_name A name given for the Virtual Account (max 140 chars)
      # @option attributes [Array<String>] :aka_names A list of AKA Names (0 to 3 items)
      # @return [Response] the API response containing virtual account details
      #
      # @example Create a virtual account
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.create(
      #     'ae07556e-22ef-11eb-adc1-0242ac120002',
      #     account_name: 'Real Estate Agency X',
      #     aka_names: ['Realestate agency X']
      #   )
      #   response.data # => {"id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", ...}
      #
      # @see https://developer.hellozai.com/reference
      def create(wallet_account_id, **attributes)
        validate_id!(wallet_account_id, 'wallet_account_id')
        validate_create_attributes!(attributes)

        body = build_create_body(attributes)
        client.post("/wallet_accounts/#{wallet_account_id}/virtual_accounts", body: body)
      end

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_create_attributes!(attributes)
        # Only validate if attributes are actually provided (not nil)
        validate_account_name!(attributes[:account_name]) if attributes.key?(:account_name)
        validate_aka_names!(attributes[:aka_names]) if attributes.key?(:aka_names)
      end

      def validate_account_name!(account_name)
        if account_name.nil? || account_name.to_s.strip.empty?
          raise Errors::ValidationError, 'account_name cannot be blank'
        end

        return unless account_name.to_s.length > 140

        raise Errors::ValidationError, 'account_name must be 140 characters or less'
      end

      def validate_aka_names!(aka_names)
        raise Errors::ValidationError, 'aka_names must be an array' unless aka_names.is_a?(Array)

        return unless aka_names.length > 3

        raise Errors::ValidationError, 'aka_names must contain between 0 and 3 items'
      end

      def build_create_body(attributes)
        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = CREATE_FIELD_MAPPING[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
