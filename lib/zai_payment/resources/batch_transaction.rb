# frozen_string_literal: true

module ZaiPayment
  module Resources
    # BatchTransaction resource for managing Zai batch transactions (Prelive only)
    #
    # @note These endpoints are only available in the prelive environment
    class BatchTransaction
      attr_reader :client, :config

      def initialize(client: nil, config: nil)
        @client = client || Client.new(base_endpoint: :core_base)
        @config = config || ZaiPayment.config
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
    end
  end
end
