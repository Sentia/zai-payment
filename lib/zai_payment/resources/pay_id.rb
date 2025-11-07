# frozen_string_literal: true

module ZaiPayment
  module Resources
    # PayID resource for managing Zai PayID registrations
    #
    # @see https://developer.hellozai.com/reference/registerpayid
    class PayId
      attr_reader :client

      # Map of attribute keys to API field names for create
      CREATE_FIELD_MAPPING = {
        pay_id: :pay_id,
        type: :type,
        details: :details
      }.freeze

      # Valid PayID types
      VALID_TYPES = %w[EMAIL].freeze

      # Valid PayID statuses for update
      VALID_STATUSES = %w[deregistered].freeze

      def initialize(client: nil)
        @client = client || Client.new(base_endpoint: :va_base)
      end

      # Register a PayID for a given Virtual Account
      #
      # @param virtual_account_id [String] the virtual account ID
      # @param attributes [Hash] PayID attributes
      # @option attributes [String] :pay_id (Required) The PayID being registered (max 256 chars)
      # @option attributes [String] :type (Required) The type of PayID ('EMAIL')
      # @option attributes [Hash] :details (Required) Additional details
      # @option details [String] :pay_id_name Name to identify the entity (1-140 chars)
      # @option details [String] :owner_legal_name Full legal account name (1-140 chars)
      # @return [Response] the API response containing PayID details
      #
      # @example Register an EMAIL PayID
      #   pay_ids = ZaiPayment::Resources::PayId.new
      #   response = pay_ids.create(
      #     '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      #     pay_id: 'jsmith@mydomain.com',
      #     type: 'EMAIL',
      #     details: {
      #       pay_id_name: 'J Smith',
      #       owner_legal_name: 'Mr John Smith'
      #     }
      #   )
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", ...}
      #
      # @see https://developer.hellozai.com/reference/registerpayid
      def create(virtual_account_id, **attributes)
        validate_id!(virtual_account_id, 'virtual_account_id')
        validate_create_attributes!(attributes)

        body = build_create_body(attributes)
        client.post("/virtual_accounts/#{virtual_account_id}/pay_ids", body: body)
      end

      # Show a specific PayID
      #
      # @param pay_id_id [String] the PayID ID
      # @return [Response] the API response containing PayID details
      #
      # @example Get PayID details
      #   pay_ids = ZaiPayment::Resources::PayId.new
      #   response = pay_ids.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", ...}
      #
      # @see https://developer.hellozai.com/reference/retrieveapayid
      def show(pay_id_id)
        validate_id!(pay_id_id, 'pay_id_id')
        client.get("/pay_ids/#{pay_id_id}")
      end

      # Update Status for a PayID
      #
      # Update the status of a PayID. Currently, this endpoint only supports deregistering
      # PayIDs by setting the status to 'deregistered'. This is an asynchronous operation
      # that returns a 202 Accepted response.
      #
      # @param pay_id_id [String] the PayID ID
      # @param status [String] the new status (must be 'deregistered')
      # @return [Response] the API response containing the operation status
      #
      # @example Deregister a PayID
      #   pay_ids = ZaiPayment::Resources::PayId.new
      #   response = pay_ids.update_status(
      #     '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
      #     'deregistered'
      #   )
      #   response.data # => {"id" => "46deb476-c1a6-41eb-8eb7-26a695bbe5bc", "message" => "...", ...}
      #
      # @see https://developer.hellozai.com/reference/updatepayidstatus
      def update_status(pay_id_id, status)
        validate_id!(pay_id_id, 'pay_id_id')
        validate_status!(status)

        body = { status: status }
        client.patch("/pay_ids/#{pay_id_id}/status", body: body)
      end

      private

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_create_attributes!(attributes)
        validate_pay_id!(attributes[:pay_id])
        validate_type!(attributes[:type])
        validate_details!(attributes[:details])
      end

      def validate_pay_id!(pay_id)
        if pay_id.nil? || pay_id.to_s.strip.empty?
          raise Errors::ValidationError, 'pay_id is required and cannot be blank'
        end

        return unless pay_id.to_s.length > 256

        raise Errors::ValidationError, 'pay_id must be 256 characters or less'
      end

      def validate_type!(type)
        raise Errors::ValidationError, 'type is required and cannot be blank' if type.nil? || type.to_s.strip.empty?

        return if VALID_TYPES.include?(type.to_s.upcase)

        raise Errors::ValidationError,
              "type must be one of: #{VALID_TYPES.join(', ')}, got '#{type}'"
      end

      def validate_details!(details)
        raise Errors::ValidationError, 'details is required and must be a hash' if details.nil? || !details.is_a?(Hash)

        validate_pay_id_name!(details[:pay_id_name])
        validate_owner_legal_name!(details[:owner_legal_name])
      end

      def validate_pay_id_name!(pay_id_name)
        return unless pay_id_name

        raise Errors::ValidationError, 'pay_id_name cannot be empty when provided' if pay_id_name.to_s.empty?

        return unless pay_id_name.to_s.length > 140

        raise Errors::ValidationError, 'pay_id_name must be between 1 and 140 characters'
      end

      def validate_owner_legal_name!(owner_legal_name)
        return unless owner_legal_name

        raise Errors::ValidationError, 'owner_legal_name cannot be empty when provided' if owner_legal_name.to_s.empty?

        return unless owner_legal_name.to_s.length > 140

        raise Errors::ValidationError, 'owner_legal_name must be between 1 and 140 characters'
      end

      def validate_status!(status)
        raise Errors::ValidationError, 'status cannot be blank' if status.nil? || status.to_s.strip.empty?

        return if VALID_STATUSES.include?(status.to_s)

        raise Errors::ValidationError,
              "status must be 'deregistered', got '#{status}'"
      end

      # rubocop:disable Metrics/AbcSize
      def build_create_body(attributes)
        body = {}

        # Add pay_id
        body[:pay_id] = attributes[:pay_id] if attributes[:pay_id]

        # Add type (convert to uppercase to match API expectations)
        body[:type] = attributes[:type].to_s.upcase if attributes[:type]

        # Add details
        if attributes[:details].is_a?(Hash)
          body[:details] = {}
          details = attributes[:details]

          body[:details][:pay_id_name] = details[:pay_id_name] if details[:pay_id_name]
          body[:details][:owner_legal_name] = details[:owner_legal_name] if details[:owner_legal_name]
        end

        body
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
