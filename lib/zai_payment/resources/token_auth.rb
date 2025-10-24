# frozen_string_literal: true

module ZaiPayment
  module Resources
    # TokenAuth resource for generating tokens for bank or card accounts
    #
    # @see https://developer.hellozai.com/reference/generatetoken
    class TokenAuth
      attr_reader :client

      # Token types
      TOKEN_TYPE_BANK = 'bank'
      TOKEN_TYPE_CARD = 'card'

      # Valid token types
      VALID_TOKEN_TYPES = [TOKEN_TYPE_BANK, TOKEN_TYPE_CARD].freeze

      def initialize(client: nil)
        @client = client || Client.new(base_endpoint: :core_base)
      end

      # Generate a token for bank or card account
      #
      # Create a token, either for a bank or a card account, that can be used with the
      # PromisePay.js package to securely send Assembly credit card details.
      #
      # @param user_id [String] (Required) Buyer or Seller ID (already created)
      # @param token_type [String] Token type ID, use 'bank' or 'card' (default: 'bank')
      # @return [Response] the API response containing generated token
      #
      # @example Generate a bank token
      #   token_auth = ZaiPayment::Resources::TokenAuth.new
      #   response = token_auth.generate(
      #     user_id: "seller-68611249",
      #     token_type: "bank"
      #   )
      #   response.data # => {"token_auth" => {"token" => "...", "user_id" => "...", ...}}
      #
      # @example Generate a card token
      #   token_auth = ZaiPayment::Resources::TokenAuth.new
      #   response = token_auth.generate(
      #     user_id: "buyer-12345",
      #     token_type: "card"
      #   )
      #
      # @see https://developer.hellozai.com/reference/generatetoken
      def generate(user_id:, token_type: TOKEN_TYPE_BANK)
        validate_user_id!(user_id)
        validate_token_type!(token_type)

        body = {
          token_type: token_type,
          user_id: user_id
        }

        client.post('/token_auths', body: body)
      end

      private

      def validate_user_id!(user_id)
        return unless user_id.nil? || user_id.to_s.strip.empty?

        raise Errors::ValidationError, 'user_id is required and cannot be blank'
      end

      def validate_token_type!(token_type)
        return if VALID_TOKEN_TYPES.include?(token_type.to_s.downcase)

        raise Errors::ValidationError,
              "token_type must be one of: #{VALID_TOKEN_TYPES.join(', ')}"
      end
    end
  end
end
