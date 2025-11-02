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

      ITEM_PAYMENT_ATTRIBUTES = {
        account_id: :account_id,
        device_id: :device_id,
        ip_address: :ip_address,
        cvv: :cvv,
        merchant_phone: :merchant_phone
      }.freeze

      ITEM_ASYNC_PAYMENT_ATTRIBUTES = {
        account_id: :account_id,
        request_three_d_secure: :request_three_d_secure
      }.freeze

      # Valid values for request_three_d_secure parameter
      REQUEST_THREE_D_SECURE_VALUES = %w[automatic challenge any].freeze

      def initialize(client: nil)
        @client = client || Client.new
      end

      # List all items
      #
      # @param limit [Integer] number of records to return (default: 10, max: 200)
      # @param offset [Integer] number of records to skip (default: 0)
      # @param search [String] optional text value to search within item description
      # @param created_before [String] optional ISO 8601 date/time to filter items created before
      #   (e.g. '2020-02-27T23:54:59Z')
      # @param created_after [String] optional ISO 8601 date/time to filter items created after
      #   (e.g. '2020-02-27T23:54:59Z')
      # @return [Response] the API response containing items array
      #
      # @example List all items
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.list
      #   response.data # => [{"id" => "...", "name" => "..."}, ...]
      #
      # @example List items with search
      #   response = items.list(search: "product")
      #
      # @example List items created within a date range
      #   response = items.list(
      #     created_after: "2024-01-01T00:00:00Z",
      #     created_before: "2024-12-31T23:59:59Z"
      #   )
      #
      # @see https://developer.hellozai.com/reference/listitems
      def list(limit: 10, offset: 0, search: nil, created_before: nil, created_after: nil)
        params = {
          limit: limit,
          offset: offset
        }

        params[:search] = search if search
        params[:created_before] = created_before if created_before
        params[:created_after] = created_after if created_after

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

      # Make a payment
      #
      # @param item_id [String] the item ID
      # @option attributes [String] :account_id Required account ID
      # @option attributes [String] :device_id Optional device ID
      # @option attributes [String] :ip_address Optional IP address
      # @option attributes [String] :cvv Optional CVV
      # @option attributes [String] :merchant_phone Optional merchant phone number
      # @return [Response] the API response containing payment details
      #
      # @example Make a payment with required parameters
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.make_payment("item_id", account_id: "account_id")
      #   response.data # => {"items" => {"id" => "...", "amount" => "...", ...}}
      #
      # @example Make a payment with optional parameters
      #   response = items.make_payment(
      #     "item_id",
      #     account_id: "account_id",
      #     device_id: "device_789",
      #     ip_address: "192.168.1.1",
      #     cvv: "123",
      #     merchant_phone: "+1234567890"
      #   )
      #
      # @see https://developer.hellozai.com/reference/makepayment
      def make_payment(item_id, **attributes)
        validate_id!(item_id, 'item_id')

        body = build_item_payment_body(attributes)

        client.patch("/items/#{item_id}/make_payment", body: body)
      end

      # Cancel an item

      # @param item_id [String] the item ID
      # @return [Response] the API response containing cancellation details
      #
      # @example Cancel a payment
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.cancel("item_id")
      #   response.data # => {"items" => {"id" => "...", "state" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/cancelitem
      def cancel(item_id)
        validate_id!(item_id, 'item_id')
        client.patch("/items/#{item_id}/cancel")
      end

      # Refund an item
      #
      # @param item_id [String] the item ID
      # @option attributes [String] :refund_amount Optional refund amount
      # @option attributes [String] :refund_message Optional refund message
      # @option attributes [String] :account_id Optional account ID
      # @return [Response] the API response containing refund details
      #
      # @example Refund an item
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.refund("item_id")
      #   response.data # => {"items" => {"id" => "...", "state" => "...", ...}}
      #
      # @example Refund an item with optional parameters
      #   response = items.refund(
      #     "item_id",
      #     refund_amount: 10000,
      #     refund_message: "Refund for product XYZ",
      #     account_id: "account_789"
      #   )
      #
      # @see https://developer.hellozai.com/reference/refund
      def refund(item_id, refund_amount: nil, refund_message: nil, account_id: nil)
        validate_id!(item_id, 'item_id')

        body = build_refund_body(
          refund_amount: refund_amount,
          refund_message: refund_message,
          account_id: account_id
        )

        client.patch("/items/#{item_id}/refund", body: body)
      end

      # Authorize Payment
      #
      # @param item_id [String] the item ID
      # @option attributes [String] :account_id Required account ID
      # @option attributes [String] :cvv Optional CVV
      # @option attributes [String] :merchant_phone Optional merchant phone number
      # @return [Response] the API response containing authorization details
      #
      # @example Authorize a payment
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.authorize_payment("item_id", account_id: "account_id")
      #   response.data # => {"items" => {"id" => "...", "state" => "...", ...}}
      #
      # @example Authorize a payment with optional parameters
      #   response = items.authorize_payment(
      #     "item_id",
      #     account_id: "account_id",
      #     cvv: "123",
      #     merchant_phone: "+1234567890"
      #   )
      #
      # @see https://developer.hellozai.com/reference/authorizepayment
      def authorize_payment(item_id, **attributes)
        validate_id!(item_id, 'item_id')

        client.patch("/items/#{item_id}/authorize_payment", body: build_item_payment_body(attributes))
      end

      # Capture Payment
      #
      # @param item_id [String] the item ID
      # @option attributes [String] :amount Optional amount to capture
      # @return [Response] the API response containing capture details
      #
      # @example Capture a payment
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.capture_payment("item_id", amount: 10000)
      #   response.data # => {"items" => {"id" => "...", "state" => "...", ...}}
      #
      # @example Capture a payment with optional parameters
      #   response = items.capture_payment(
      #     "item_id",
      #     amount: 10000
      #   )
      #
      # @see https://developer.hellozai.com/reference/capturepayment
      def capture_payment(item_id, **attributes)
        validate_id!(item_id, 'item_id')

        body = {}
        body[:amount] = attributes[:amount] if attributes[:amount]

        client.patch("/items/#{item_id}/capture_payment", body: body)
      end

      # Void Payment
      #
      # @param item_id [String] the item ID
      # @return [Response] the API response containing void details
      #
      # @example Void a payment
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.void_payment("item_id")
      #   response.data # => {"items" => {"id" => "...", "state" => "...", ...}}
      #
      # @see https://developer.hellozai.com/reference/voidpayment
      def void_payment(item_id)
        validate_id!(item_id, 'item_id')
        client.patch("/items/#{item_id}/void_payment")
      end

      # Make an async Payment
      #
      # Initiate a card payment with 3D Secure 2.0 authentication support. This endpoint
      # initiates the payment process and returns a payment_token required for 3DS2
      # component initialisation.
      #
      # @param item_id [String] the item ID
      # @param account_id [String] Account id of the bank account/credit card, etc making payment (not user id)
      # @option attributes [String] :request_three_d_secure Customise the 3DS (3D Secure) preference for this payment.
      #   Allowed values: 'automatic', 'challenge', 'any'. Defaults to 'automatic'.
      #   - 'automatic': 3DS preference is determined automatically by the system
      #   - 'challenge': Request a 3DS challenge is presented to the user
      #   - 'any': Request a 3DS challenge regardless of the challenge flow
      # @return [Response] the API response containing payment details with payment_token
      #
      # @example Make an async payment with required parameters
      #   items = ZaiPayment::Resources::Item.new
      #   response = items.make_payment_async("item_id", account_id: "account_id")
      #   response.data # => {"payment_id" => "...", "payment_token" => "...", "items" => {...}}
      #
      # @example Make an async payment with 3DS challenge
      #   response = items.make_payment_async(
      #     "item_id",
      #     account_id: "account_id",
      #     request_three_d_secure: "challenge"
      #   )
      #
      # @see https://developer.hellozai.com/reference/makepaymentasync
      def make_payment_async(item_id, **attributes)
        validate_id!(item_id, 'item_id')

        body = build_async_payment_body(attributes)

        client.patch("/items/#{item_id}/make_payment_async", body: body)
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

      def validate_request_three_d_secure!(value)
        return if REQUEST_THREE_D_SECURE_VALUES.include?(value.to_s)

        raise Errors::ValidationError,
              "request_three_d_secure must be one of: #{REQUEST_THREE_D_SECURE_VALUES.join(', ')}"
      end

      def build_item_payment_body(attributes)
        validate_presence!(attributes[:account_id], 'account_id')

        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = ITEM_PAYMENT_ATTRIBUTES[key]
          body[api_field] = value if api_field
        end

        body
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

      def build_refund_body(refund_amount: nil, refund_message: nil, account_id: nil)
        body = {}

        body[:refund_amount] = refund_amount if refund_amount
        body[:refund_message] = refund_message if refund_message
        body[:account_id] = account_id if account_id

        body
      end

      def build_async_payment_body(attributes)
        validate_presence!(attributes[:account_id], 'account_id')

        # Validate request_three_d_secure if provided
        validate_request_three_d_secure!(attributes[:request_three_d_secure]) if attributes[:request_three_d_secure]

        body = {}

        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          api_field = ITEM_ASYNC_PAYMENT_ATTRIBUTES[key]
          body[api_field] = value if api_field
        end

        body
      end
    end
  end
end
