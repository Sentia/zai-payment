# frozen_string_literal: true

require 'faraday'

module ZaiPayment
  module Auth
    class TokenProvider
      def initialize(config:, store: nil)
        @config = config
        @store  = store || TokenStores::MemoryStore.new
        @mutex  = Mutex.new
      end

      # Returns "Bearer <token>"
      def bearer_token
        token = @store.fetch
        return "Bearer #{token.value}" if token && Time.now < token.expires_at

        @mutex.synchronize do
          token = @store.fetch
          return "Bearer #{token.value}" if token && Time.now < token.expires_at

          new_token = request_token!
          @store.write(new_token)
          "Bearer #{new_token.value}"
        end
      end

      # Force refresh: clears current token then fetches a new one
      def refresh_token
        clear_token
        bearer_token
      end

      # Clear cached token (next call will re-auth)
      def clear_token
        @store.clear
      end

      # Returns a Time (or nil if no token cached)
      def token_expiry
        token = @store.fetch
        token&.expires_at
      end

      # Returns the token type string (e.g., "Bearer") or nil if none cached
      def token_type
        token = @store.fetch
        token&.type
      end

      private

      def request_token!
        resp = perform_token_request
        parse_token_response(resp)
      rescue Faraday::Error => e
        raise ZaiPayment::Errors::AuthError, "Token request failed: #{e.message}"
      end

      def perform_token_request
        connection.post('/tokens') do |req|
          req.body = {
            grant_type: 'client_credentials',
            client_id: @config.client_id,
            client_secret: @config.client_secret,
            scope: @config.scope
          }
        end
      end

      def connection
        Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.response :json
          faraday.adapter Faraday.default_adapter
          faraday.url_prefix = @config.endpoints[:auth_base]
        end
      end

      def parse_token_response(resp)
        data = resp.body
        token_value = data['access_token'] || data['token']
        expires_in  = (data['expires_in'] || 3600).to_i
        token_type  = data['token_type'] || 'Bearer'

        raise ZaiPayment::Errors::AuthError, 'No access_token found' unless token_value

        TokenStore::Token.new(
          value: token_value,
          expires_at: Time.now + expires_in - 60,
          type: token_type
        )
      end
    end
  end
end
