# frozen_string_literal: true

module ZaiPayment
  module Resources
    # VirtualAccount resource for managing Zai virtual accounts
    #
    # @see https://developer.hellozai.com/reference/createvirtualaccount
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

      # List Virtual Accounts for a given Wallet Account
      #
      # @param wallet_account_id [String] the wallet account ID
      # @return [Response] the API response containing array of virtual accounts
      #
      # @example List virtual accounts
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.list('ae07556e-22ef-11eb-adc1-0242ac120002')
      #   response.data # => [{"id" => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", ...}, ...]
      #   response.meta # => {"total" => 2}
      #
      # @see https://developer.hellozai.com/reference
      def list(wallet_account_id)
        validate_id!(wallet_account_id, 'wallet_account_id')
        client.get("/wallet_accounts/#{wallet_account_id}/virtual_accounts")
      end

      # Show a specific Virtual Account
      #
      # @param virtual_account_id [String] the virtual account ID
      # @return [Response] the API response containing virtual account details
      #
      # @example Get virtual account details
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", ...}
      #
      # @see https://developer.hellozai.com/reference/showvirtualaccount
      def show(virtual_account_id)
        validate_id!(virtual_account_id, 'virtual_account_id')
        client.get("/virtual_accounts/#{virtual_account_id}")
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
      # @see https://developer.hellozai.com/reference/listvirtualaccountbywalletaccount
      def create(wallet_account_id, **attributes)
        validate_id!(wallet_account_id, 'wallet_account_id')
        validate_create_attributes!(attributes)

        body = build_create_body(attributes)
        client.post("/wallet_accounts/#{wallet_account_id}/virtual_accounts", body: body)
      end

      # Update AKA Names for a Virtual Account
      #
      # Replace the list of AKA Names for a Virtual Account. This completely replaces
      # the existing AKA names with the new list provided.
      #
      # @param virtual_account_id [String] the virtual account ID
      # @param aka_names [Array<String>] array of AKA names (0 to 3 items)
      # @return [Response] the API response containing updated virtual account details
      #
      # @example Update AKA names
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.update_aka_names(
      #     '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      #     ['New Name 1', 'New Name 2']
      #   )
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", ...}
      #
      # @see https://developer.hellozai.com/reference/updatevirtualaccountakaname
      def update_aka_names(virtual_account_id, aka_names)
        validate_id!(virtual_account_id, 'virtual_account_id')
        validate_aka_names!(aka_names)

        body = { aka_names: aka_names }
        client.patch("/virtual_accounts/#{virtual_account_id}/aka_names", body: body)
      end

      # Update Account Name for a Virtual Account
      #
      # Change the name of a Virtual Account. This is used in CoP lookups.
      #
      # @param virtual_account_id [String] the virtual account ID
      # @param account_name [String] the new account name (max 140 characters)
      # @return [Response] the API response containing updated virtual account details
      #
      # @example Update account name
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.update_account_name(
      #     '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      #     'New Real Estate Agency Name'
      #   )
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", ...}
      #
      # @see https://developer.hellozai.com/reference/updatevirtualaccountaccountname
      def update_account_name(virtual_account_id, account_name)
        validate_id!(virtual_account_id, 'virtual_account_id')
        validate_account_name!(account_name)

        body = { account_name: account_name }
        client.patch("/virtual_accounts/#{virtual_account_id}/account_name", body: body)
      end

      # Update Status for a Virtual Account
      #
      # Close a Virtual Account. Once closed, the account cannot be reopened and will
      # no longer be able to receive payments. This operation is asynchronous and returns
      # a 202 Accepted response.
      #
      # @param virtual_account_id [String] the virtual account ID
      # @param status [String] the new status (must be 'closed')
      # @return [Response] the API response containing the operation status
      #
      # @example Close a virtual account
      #   virtual_accounts = ZaiPayment::Resources::VirtualAccount.new
      #   response = virtual_accounts.update_status(
      #     '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      #     'closed'
      #   )
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", "message" => "...", ...}
      #
      # @see https://developer.hellozai.com/reference/updatevirtualaccount
      def update_status(virtual_account_id, status)
        validate_id!(virtual_account_id, 'virtual_account_id')
        validate_status!(status)

        body = { status: status }
        client.patch("/virtual_accounts/#{virtual_account_id}/status", body: body)
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

      def validate_status!(status)
        raise Errors::ValidationError, 'status cannot be blank' if status.nil? || status.to_s.strip.empty?

        return if status.to_s == 'closed'

        raise Errors::ValidationError, "status must be 'closed', got '#{status}'"
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
