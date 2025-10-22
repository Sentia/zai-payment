# frozen_string_literal: true

require 'openssl'
require 'base64'

module ZaiPayment
  module Resources
    # Webhook resource for managing Zai webhooks
    #
    # @see https://developer.hellozai.com/reference/getallwebhooks
    class Webhook
      attr_reader :client

      def initialize(client: nil)
        @client = client || Client.new
      end

      # List all webhooks
      #
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing webhooks array
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   response = webhooks.list
      #   response.data # => [{"id" => "...", "url" => "..."}, ...]
      #
      # @see https://developer.hellozai.com/reference/getallwebhooks
      def list(limit: 10, offset: 0)
        params = {
          limit: limit,
          offset: offset
        }

        client.get('/webhooks', params: params)
      end

      # Get a specific webhook by ID
      #
      # @param webhook_id [String] the webhook ID
      # @return [Response] the API response containing webhook details
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   response = webhooks.show("webhook_id")
      #   response.data # => {"id" => "webhook_id", "url" => "...", ...}
      #
      # @see https://developer.hellozai.com/reference/getwebhookbyid
      def show(webhook_id)
        validate_id!(webhook_id, 'webhook_id')
        client.get("/webhooks/#{webhook_id}")
      end

      # Create a new webhook
      #
      # @param url [String] the webhook URL to receive notifications
      # @param object_type [String] the type of object to watch (e.g., 'transactions', 'items')
      # @param enabled [Boolean] whether the webhook is enabled (default: true)
      # @param description [String] optional description of the webhook
      # @return [Response] the API response containing created webhook
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   response = webhooks.create(
      #     url: "https://example.com/webhooks",
      #     object_type: "transactions",
      #     enabled: true
      #   )
      #
      # @see https://developer.hellozai.com/reference/createwebhook
      def create(url: nil, object_type: nil, enabled: true, description: nil)
        validate_presence!(url, 'url')
        validate_presence!(object_type, 'object_type')
        validate_url!(url)

        body = {
          url: url,
          object_type: object_type,
          enabled: enabled
        }

        body[:description] = description if description

        client.post('/webhooks', body: body)
      end

      # Update an existing webhook
      #
      # @param webhook_id [String] the webhook ID
      # @param url [String] optional new webhook URL
      # @param object_type [String] optional new object type
      # @param enabled [Boolean] optional enabled status
      # @param description [String] optional description
      # @return [Response] the API response containing updated webhook
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   response = webhooks.update(
      #     "webhook_id",
      #     enabled: false
      #   )
      #
      # @see https://developer.hellozai.com/reference/updatewebhook
      def update(webhook_id, url: nil, object_type: nil, enabled: nil, description: nil)
        validate_id!(webhook_id, 'webhook_id')

        body = {}
        body[:url] = url if url
        body[:object_type] = object_type if object_type
        body[:enabled] = enabled unless enabled.nil?
        body[:description] = description if description

        validate_url!(url) if url

        raise Errors::ValidationError, 'At least one attribute must be provided for update' if body.empty?

        client.patch("/webhooks/#{webhook_id}", body: body)
      end

      # Delete a webhook
      #
      # @param webhook_id [String] the webhook ID
      # @return [Response] the API response
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   response = webhooks.delete("webhook_id")
      #
      # @see https://developer.hellozai.com/reference/deletewebhook
      def delete(webhook_id)
        validate_id!(webhook_id, 'webhook_id')
        client.delete("/webhooks/#{webhook_id}")
      end

      # Create a secret key for webhook signature verification
      #
      # @param secret_key [String] the secret key to use for HMAC signature generation
      #   Must be ASCII characters and at least 32 bytes in size
      # @return [Response] the API response
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   secret_key = SecureRandom.alphanumeric(32)
      #   response = webhooks.create_secret_key(secret_key: secret_key)
      #
      # @see https://developer.hellozai.com/reference/createsecretkey
      # @see https://developer.hellozai.com/docs/verify-webhook-signatures
      def create_secret_key(secret_key:)
        validate_presence!(secret_key, 'secret_key')
        validate_secret_key!(secret_key)

        body = { secret_key: secret_key }
        client.post('/webhooks/secret_key', body: body)
      end

      # Verify webhook signature
      #
      # This method verifies that a webhook request came from Zai by validating
      # the HMAC SHA256 signature in the Webhooks-signature header.
      #
      # @param payload [String] the raw request body (JSON string)
      # @param signature_header [String] the Webhooks-signature header value
      # @param secret_key [String] your secret key used for signature generation
      # @param tolerance [Integer] maximum age of webhook in seconds (default: 300 = 5 minutes)
      # @return [Boolean] true if signature is valid and within tolerance
      # @raise [Errors::ValidationError] if signature is invalid or timestamp is outside tolerance
      #
      # @example
      #   # In your webhook endpoint (e.g., Rails controller)
      #   def webhook
      #     payload = request.body.read
      #     signature_header = request.headers['Webhooks-signature']
      #     secret_key = ENV['ZAI_WEBHOOK_SECRET']
      #
      #     if ZaiPayment.webhooks.verify_signature(
      #       payload: payload,
      #       signature_header: signature_header,
      #       secret_key: secret_key
      #     )
      #       # Process webhook
      #       render json: { status: 'success' }
      #     else
      #       render json: { error: 'Invalid signature' }, status: :unauthorized
      #     end
      #   end
      #
      # @see https://developer.hellozai.com/docs/verify-webhook-signatures
      def verify_signature(payload:, signature_header:, secret_key:, tolerance: 300)
        validate_presence!(payload, 'payload')
        validate_presence!(signature_header, 'signature_header')
        validate_presence!(secret_key, 'secret_key')

        # Extract timestamp and signature from header
        timestamp, signatures = parse_signature_header(signature_header)

        # Verify timestamp is within tolerance (prevent replay attacks)
        verify_timestamp!(timestamp, tolerance)

        # Generate expected signature
        expected_signature = generate_signature(payload, secret_key, timestamp)

        # Compare signatures using constant-time comparison
        signatures.any? { |sig| secure_compare(expected_signature, sig) }
      end

      # Generate a signature for webhook verification
      #
      # This is a utility method that can be used for testing or generating
      # signatures for webhook simulation.
      #
      # @param payload [String] the request body (JSON string)
      # @param secret_key [String] the secret key
      # @param timestamp [Integer] the Unix timestamp (defaults to current time)
      # @return [String] the base64url-encoded HMAC SHA256 signature
      #
      # @example
      #   webhooks = ZaiPayment::Resources::Webhook.new
      #   signature = webhooks.generate_signature(
      #     '{"event": "status_updated"}',
      #     'my_secret_key'
      #   )
      #
      # @see https://developer.hellozai.com/docs/verify-webhook-signatures
      def generate_signature(payload, secret_key, timestamp = Time.now.to_i)
        signed_payload = "#{timestamp}.#{payload}"
        digest = OpenSSL::Digest.new('sha256')
        hash = OpenSSL::HMAC.digest(digest, secret_key, signed_payload)
        Base64.urlsafe_encode64(hash, padding: false)
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

      def validate_url!(url)
        uri = URI.parse(url)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise Errors::ValidationError, 'url must be a valid HTTP or HTTPS URL'
        end
      rescue URI::InvalidURIError
        raise Errors::ValidationError, 'url must be a valid URL'
      end

      def validate_secret_key!(secret_key)
        # Check if it's ASCII
        raise Errors::ValidationError, 'secret_key must contain only ASCII characters' unless secret_key.ascii_only?

        # Check minimum length (32 bytes)
        return unless secret_key.bytesize < 32

        raise Errors::ValidationError, 'secret_key must be at least 32 bytes in size'
      end

      def parse_signature_header(header)
        # Format: "t=1257894000,v=signature1,v=signature2"
        parts = header.split(',').map(&:strip)

        timestamp = nil
        signatures = []

        parts.each do |part|
          key, value = part.split('=', 2)
          case key
          when 't'
            timestamp = value.to_i
          when 'v'
            signatures << value
          end
        end

        if timestamp.nil? || timestamp.zero?
          raise Errors::ValidationError, 'Invalid signature header: missing or invalid timestamp'
        end

        raise Errors::ValidationError, 'Invalid signature header: missing signature' if signatures.empty?

        [timestamp, signatures]
      end

      def verify_timestamp!(timestamp, tolerance)
        current_time = Time.now.to_i
        time_diff = (current_time - timestamp).abs

        return unless time_diff > tolerance

        raise Errors::ValidationError,
              "Webhook timestamp is outside tolerance (#{time_diff}s vs #{tolerance}s max). " \
              'This may be a replay attack.'
      end

      # Constant-time string comparison to prevent timing attacks
      # Uses OpenSSL's secure_compare if available, otherwise falls back to manual comparison
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        if defined?(OpenSSL.fixed_length_secure_compare)
          OpenSSL.fixed_length_secure_compare(a, b)
        else
          # Fallback for older Ruby versions
          result = 0
          a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
          result.zero?
        end
      end
    end
  end
end
