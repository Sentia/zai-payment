# frozen_string_literal: true

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
    end
  end
end
