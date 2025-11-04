# frozen_string_literal: true

module ZaiPayment
  module Resources
    # BatchTransaction resource for managing Zai batch transactions (Prelive only)
    #
    # @note These endpoints are only available in the prelive environment
    class BatchTransaction
      attr_reader :client, :config

      # Valid transaction types
      TRANSACTION_TYPES = %w[payment refund disbursement fee deposit withdrawal].freeze

      # Valid transaction type methods
      TRANSACTION_TYPE_METHODS = %w[credit_card npp bpay wallet_account_transfer wire_transfer misc].freeze

      # Valid directions
      DIRECTIONS = %w[debit credit].freeze

      def initialize(client: nil, config: nil)
        @client = client || Client.new(base_endpoint: :core_base)
        @config = config || ZaiPayment.config
      end

      # List batch transactions
      #
      # Retrieve an ordered and paginated list of existing batch transactions.
      # The list can be filtered by account, batch ID, item, and transaction type.
      #
      # @param options [Hash] optional filters
      # @option options [Integer] :limit number of records to return (default: 10, max: 200)
      # @option options [Integer] :offset number of records to skip (default: 0)
      # @option options [String] :account_id Bank, Card or Wallet Account ID
      # @option options [String] :batch_id Batch ID
      # @option options [String] :item_id Item ID
      # @option options [String] :transaction_type transaction type
      #   (payment, refund, disbursement, fee, deposit, withdrawal)
      # @option options [String] :transaction_type_method transaction method (credit_card, npp, bpay, etc.)
      # @option options [String] :direction direction (debit, credit)
      # @option options [String] :created_before ISO 8601 date/time to filter transactions created before
      # @option options [String] :created_after ISO 8601 date/time to filter transactions created after
      # @option options [String] :disbursement_bank the bank used for disbursing the payment
      # @option options [String] :processing_bank the bank used for processing the payment
      # @return [Response] the API response containing batch_transactions array
      #
      # @example List all batch transactions
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.list
      #   response.data # => [{"id" => 12484, "status" => 12200, ...}]
      #
      # @example List with filters
      #   response = batch_transactions.list(
      #     transaction_type: 'disbursement',
      #     direction: 'credit',
      #     limit: 50
      #   )
      #
      # @see https://developer.hellozai.com/reference/listbatchtransactions
      def list(**options)
        validate_list_options(options)

        params = build_list_params(options)

        client.get('/batch_transactions', params: params)
      end

      # Show a batch transaction
      #
      # Get a batch transaction using its ID (UUID or numeric ID).
      #
      # @param id [String] the batch transaction ID
      # @return [Response] the API response containing batch_transactions object
      #
      # @example Get a batch transaction by UUID
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.show('90c1418b-f4f4-413e-a4ba-f29c334e7f55')
      #   response.data # => {"id" => 13143, "uuid" => "90c1418b-f4f4-413e-a4ba-f29c334e7f55", ...}
      #
      # @example Get a batch transaction by numeric ID
      #   response = batch_transactions.show('13143')
      #   response.data['state'] # => "successful"
      #
      # @raise [Errors::ValidationError] if id is blank
      #
      # @see https://developer.hellozai.com/reference/showbatchtransaction
      def show(id)
        validate_id!(id, 'id')

        client.get("/batch_transactions/#{id}")
      end

      # Export batch transactions (Prelive only)
      #
      # Calls the GET /batch_transactions/export_transactions API which moves all pending
      # batch_transactions into batched state. As a result, this API will return all the
      # batch_transactions that have moved from pending to batched. Please store the id
      # in order to progress it in Pre-live.
      #
      # @return [Response] the API response containing transactions array with batch_id
      #
      # @example Export transactions
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.export_transactions
      #   response.data # => {"transactions" => [{"id" => "...", "batch_id" => "...", "status" => "batched", ...}]}
      #
      # @raise [Errors::ConfigurationError] if not in prelive environment
      #
      # @see https://developer.hellozai.com/reference (Prelive endpoints)
      def export_transactions
        ensure_prelive_environment!

        client.get('/batch_transactions/export_transactions')
      end

      # Update batch transaction states (Prelive only)
      #
      # Calls the PATCH /batches/:id/transaction_states API which moves one or more
      # batch_transactions into a specific state. You will need to pass in the batch_id
      # from the export_transactions response.
      #
      # State codes:
      # - 12700: bank_processing state
      # - 12000: successful state (final state, triggers webhook)
      #
      # @param batch_id [String] the batch ID from export_transactions response
      # @param exported_ids [Array<String>] array of transaction IDs to update
      # @param state [Integer] the target state code (12700 or 12000)
      # @return [Response] the API response containing job information
      #
      # @example Move transactions to bank_processing state
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.update_transaction_states(
      #     "batch_id",
      #     exported_ids: ["439970a2-e0a1-418e-aecf-6b519c115c55"],
      #     state: 12700
      #   )
      #   response.body # => {
      #     "aggregated_jobs_uuid" => "c1cbc502-9754-42fd-9731-2330ddd7a41f",
      #     "msg" => "1 jobs have been sent to the queue.",
      #     "errors" => []
      #   }
      #
      # @example Move transactions to successful state
      #   response = batch_transactions.update_transaction_states(
      #     "batch_id",
      #     exported_ids: ["439970a2-e0a1-418e-aecf-6b519c115c55"],
      #     state: 12000
      #   )
      #   response.body # => {
      #     "aggregated_jobs_uuid" => "...",
      #     "msg" => "1 jobs have been sent to the queue.",
      #     "errors" => []
      #   }
      #
      # @raise [Errors::ConfigurationError] if not in prelive environment
      # @raise [Errors::ValidationError] if parameters are invalid
      #
      # @see https://developer.hellozai.com/reference (Prelive endpoints)
      def update_transaction_states(batch_id, exported_ids:, state:)
        ensure_prelive_environment!
        validate_id!(batch_id, 'batch_id')
        validate_exported_ids!(exported_ids)
        validate_state!(state)

        body = {
          exported_ids: exported_ids,
          state: state
        }

        client.patch("/batches/#{batch_id}/transaction_states", body: body)
      end

      # Move transactions to bank_processing state (Prelive only)
      #
      # Convenience method that calls update_transaction_states with state 12700.
      # This simulates the step where transactions are moved to bank_processing state.
      #
      # @param batch_id [String] the batch ID from export_transactions response
      # @param exported_ids [Array<String>] array of transaction IDs to update
      # @return [Response] the API response with aggregated_jobs_uuid, msg, and errors
      #
      # @example
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.process_to_bank_processing(
      #     "batch_id",
      #     exported_ids: ["439970a2-e0a1-418e-aecf-6b519c115c55"]
      #   )
      #   response.body["msg"] # => "1 jobs have been sent to the queue."
      #
      # @raise [Errors::ConfigurationError] if not in prelive environment
      # @raise [Errors::ValidationError] if parameters are invalid
      def process_to_bank_processing(batch_id, exported_ids:)
        update_transaction_states(batch_id, exported_ids: exported_ids, state: 12_700)
      end

      # Move transactions to successful state (Prelive only)
      #
      # Convenience method that calls update_transaction_states with state 12000.
      # This simulates the final step where transactions are marked as successful
      # and triggers the batch_transactions webhook.
      #
      # @param batch_id [String] the batch ID from export_transactions response
      # @param exported_ids [Array<String>] array of transaction IDs to update
      # @return [Response] the API response with aggregated_jobs_uuid, msg, and errors
      #
      # @example
      #   batch_transactions = ZaiPayment.batch_transactions
      #   response = batch_transactions.process_to_successful(
      #     "batch_id",
      #     exported_ids: ["439970a2-e0a1-418e-aecf-6b519c115c55"]
      #   )
      #   response.body["msg"] # => "1 jobs have been sent to the queue."
      #
      # @raise [Errors::ConfigurationError] if not in prelive environment
      # @raise [Errors::ValidationError] if parameters are invalid
      def process_to_successful(batch_id, exported_ids:)
        update_transaction_states(batch_id, exported_ids: exported_ids, state: 12_000)
      end

      private

      def ensure_prelive_environment!
        return if config.environment.to_sym == :prelive

        raise Errors::ConfigurationError,
              'Batch transaction endpoints are only available in prelive environment. ' \
              "Current environment: #{config.environment}"
      end

      def validate_id!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise Errors::ValidationError, "#{field_name} is required and cannot be blank"
      end

      def validate_exported_ids!(exported_ids)
        if exported_ids.nil? || !exported_ids.is_a?(Array) || exported_ids.empty?
          raise Errors::ValidationError,
                'exported_ids is required and must be a non-empty array'
        end

        return unless exported_ids.any? { |id| id.nil? || id.to_s.strip.empty? }

        raise Errors::ValidationError,
              'exported_ids cannot contain nil or empty values'
      end

      def validate_state!(state)
        valid_states = [12_700, 12_000]

        return if valid_states.include?(state)

        raise Errors::ValidationError,
              "state must be 12700 (bank_processing) or 12000 (successful), got: #{state}"
      end

      def validate_transaction_type!(transaction_type)
        return if TRANSACTION_TYPES.include?(transaction_type.to_s)

        raise Errors::ValidationError,
              "transaction_type must be one of: #{TRANSACTION_TYPES.join(', ')}"
      end

      def validate_transaction_type_method!(transaction_type_method)
        return if TRANSACTION_TYPE_METHODS.include?(transaction_type_method.to_s)

        raise Errors::ValidationError,
              "transaction_type_method must be one of: #{TRANSACTION_TYPE_METHODS.join(', ')}"
      end

      def validate_direction!(direction)
        return if DIRECTIONS.include?(direction.to_s)

        raise Errors::ValidationError,
              "direction must be one of: #{DIRECTIONS.join(', ')}"
      end

      def validate_list_options(options)
        validate_transaction_type!(options[:transaction_type]) if options[:transaction_type]
        validate_transaction_type_method!(options[:transaction_type_method]) if options[:transaction_type_method]
        validate_direction!(options[:direction]) if options[:direction]
      end

      def build_list_params(options)
        {
          limit: options.fetch(:limit, 10),
          offset: options.fetch(:offset, 0),
          account_id: options[:account_id],
          batch_id: options[:batch_id],
          item_id: options[:item_id],
          transaction_type: options[:transaction_type],
          transaction_type_method: options[:transaction_type_method],
          direction: options[:direction],
          created_before: options[:created_before],
          created_after: options[:created_after],
          disbursement_bank: options[:disbursement_bank],
          processing_bank: options[:processing_bank]
        }.compact
      end
    end
  end
end
