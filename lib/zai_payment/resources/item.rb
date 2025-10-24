# frozen_string_literal: true

module ZaiPayment
  module Resources
    # Item resource for managing Zai items (transactions/payments)
    #
    # @see https://developer.hellozai.com/reference/listitems
    class Item
      attr_reader :client

      # Map of attribute keys to API field names
      FIELD_MAPPING = {
        id: :id,
        name: :name,
        amount: :amount,
        payment_type: :payment_type,
        buyer_id: :buyer_id,
        seller_id: :seller_id,
        fee_ids: :fee_ids,
        description: :description,
        currency: :currency,
        custom_descriptor: :custom_descriptor,
        buyer_url: :buyer_url,
        seller_url: :seller_url,
        tax_invoice: :tax_invoice
      }.freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # List all items
      #
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing items array
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.list
      #   response.data # => {"items" => [{"id" => "...", "name" => "..."}, ...]}
      #
      # @see https://developer.hellozai.com/reference/listitems
      def list(limit: 10, offset: 0)
        params = {
          limit: limit,
          offset: offset
        }

        client.get('/items', params: params)
      end

      # Get a specific item by ID
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing item details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show("item_id")
      #   response.data # => {"items" => {"id" => "item_id", "name" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/showitem
      def show(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}")
      end

      # Create a new item
      #
      # @param attributes [Hash] item attributes
      # @option attributes [String] :id Optional unique ID for the item
      # @option attributes [String] :name (Required) Name of the item
      # @option attributes [Integer] :amount (Required) Amount in cents
      # @option attributes [String] :payment_type (Required) Payment type (1-7, default: 2)
      # @option attributes [String] :buyer_id (Required) Buyer user ID
      # @option attributes [String] :seller_id (Required) Seller user ID
      # @option attributes [Array<String>] :fee_ids Optional array of fee IDs
      # @option attributes [String] :description Optional description
      # @option attributes [String] :currency Optional currency code (e.g., 'AUD')
      # @option attributes [String] :custom_descriptor Optional custom descriptor
      # @option attributes [String] :buyer_url Optional buyer URL
      # @option attributes [String] :seller_url Optional seller URL
      # @option attributes [Boolean] :tax_invoice Optional tax invoice flag
      # @return [Response] the API response containing created item
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.create(
      #     name: "Product Purchase",
      #     amount: 10000,
      #     payment_type: 2,
      #     buyer_id: "buyer-123",
      #     seller_id: "seller-456",
      #     description: "Purchase of product XYZ"
      #   )
      #
      # @see https://developer.hellozai.com/reference/createitem
      def create(**attributes)
        validate_create_attributes!(attributes)

        body = build_item_body(attributes)
        client.post('/items', body: body)
      end

      # Update an existing item
      #
      # @param item_id [String] the item ID
      # @param attributes [Hash] item attributes to update
      # @option attributes [String] :name Name of the item
      # @option attributes [Integer] :amount Amount in cents
      # @option attributes [String] :description Description
      # @option attributes [String] :buyer_id Buyer user ID
      # @option attributes [String] :seller_id Seller user ID
      # @option attributes [Array<String>] :fee_ids Array of fee IDs
      # @option attributes [String] :custom_descriptor Custom descriptor
      # @option attributes [String] :buyer_url Buyer URL
      # @option attributes [String] :seller_url Seller URL
      # @option attributes [Boolean] :tax_invoice Tax invoice flag
      # @return [Response] the API response containing updated item
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.update(
      #     "item_id",
      #     name: "Updated Product Name",
      #     description: "Updated description"
      #   )
      #
      # @see https://developer.hellozai.com/reference/updateitem
      def update(item_id, **attributes)
        validate_id!(item_id, 'item_id')

        body = build_item_body(attributes)

        raise Errors::ValidationError, 'At least one attribute must be provided for update' if body.empty?

        client.patch("/items/#{item_id}", body: body)
      end

      # Delete an item
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.delete("item_id")
      #
      # @see https://developer.hellozai.com/reference/deleteitem
      def delete(item_id)
        validate_id!(item_id, 'item_id')
        client.delete("/items/#{item_id}")
      end

      # Show item seller
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing seller details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show_seller("item_id")
      #   response.data # => {"users" => {"id" => "...", "email" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/showitemseller
      def show_seller(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}/sellers")
      end

      # Show item buyer
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing buyer details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show_buyer("item_id")
      #   response.data # => {"users" => {"id" => "...", "email" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/showitembuyer
      def show_buyer(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}/buyers")
      end

      # Show item fees
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing fees details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show_fees("item_id")
      #   response.data # => {"fees" => [{"id" => "...", "amount" => "...", ...}]}
      #
      # @see https://developer.hellozai.com/reference/showitemfees
      def show_fees(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}/fees")
      end

      # Show item wire details
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing wire transfer details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show_wire_details("item_id")
      #   response.data # => {"items" => {"wire_details" => {...}}}
      #
      # @see https://developer.hellozai.com/reference/showitemwiredetails
      def show_wire_details(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}/wire_details")
      end

      # List item transactions
      #
      # @param item_id [String] the item ID
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing transactions array
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.list_transactions("item_id")
      #   response.data # => {"transactions" => [{"id" => "...", "amount" => "...", ...}]}
      #
      # @see https://developer.hellozai.com/reference/listitemtransactions
      def list_transactions(item_id, limit: 10, offset: 0)
        validate_id!(item_id, 'item_id')

        params = {
          limit: limit,
          offset: offset
        }

        client.get("/items/#{item_id}/transactions", params: params)
      end

      # List item batch transactions
      #
      # @param item_id [String] the item ID
      # @param limit [Integer] number of records to return (default: 10)
      # @param offset [Integer] number of records to skip (default: 0)
      # @return [Response] the API response containing batch transactions array
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.list_batch_transactions("item_id")
      #   response.data # => {"batch_transactions" => [{"id" => "...", ...}]}
      #
      # @see https://developer.hellozai.com/reference/listitembatchtransactions
      def list_batch_transactions(item_id, limit: 10, offset: 0)
        validate_id!(item_id, 'item_id')

        params = {
          limit: limit,
          offset: offset
        }

        client.get("/items/#{item_id}/batch_transactions", params: params)
      end

      # Show item status
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing status details
      #
      # @example
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.show_status("item_id")
      #   response.data # => {"items" => {"state" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/showitemstatus
      def show_status(item_id)
        validate_id!(item_id, 'item_id')
        client.get("/items/#{item_id}/status")
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

      def validate_create_attributes!(attributes)
        validate_required_attributes!(attributes)
        validate_amount!(attributes[:amount]) if attributes[:amount]
        validate_payment_type!(attributes[:payment_type]) if attributes[:payment_type]
      end

      def validate_required_attributes!(attributes)
        required_fields = %i[name amount payment_type buyer_id seller_id]

        missing_fields = required_fields.select do |field|
          attributes[field].nil? || (attributes[field].respond_to?(:empty?) && attributes[field].to_s.strip.empty?)
        end

        return if missing_fields.empty?

        raise Errors::ValidationError,
              "Missing required fields: #{missing_fields.join(', ')}"
      end

      def validate_amount!(amount)
        return if amount.is_a?(Integer) && amount.positive?

        raise Errors::ValidationError, 'amount must be a positive integer (in cents)'
      end

      def validate_payment_type!(payment_type)
        # Payment types: 1-7 (2 is default)
        valid_types = %w[1 2 3 4 5 6 7]
        return if valid_types.include?(payment_type.to_s)

        raise Errors::ValidationError, 'payment_type must be between 1 and 7'
      end

      def build_item_body(attributes)
        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = FIELD_MAPPING[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
