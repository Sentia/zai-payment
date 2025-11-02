# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::Item do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:item_resource) { described_class.new(client: test_client) }

  let(:test_client) do
    config = ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end

    token_provider = instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
    client = ZaiPayment::Client.new(config: config, token_provider: token_provider)

    test_connection = Faraday.new do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter :test, stubs
    end

    allow(client).to receive(:connection).and_return(test_connection)
    client
  end

  after do
    stubs.verify_stubbed_calls
  end

  describe '#list' do
    context 'when successful' do
      before do
        stubs.get('/items') do |env|
          [200, { 'Content-Type' => 'application/json' }, item_list_data] if env.params['limit'] == '10'
        end
      end

      let(:item_list_data) do
        {
          'items' => [
            {
              'id' => 'item_1',
              'name' => 'Product A',
              'amount' => 10_000,
              'payment_type' => 2,
              'buyer_id' => 'buyer_123',
              'seller_id' => 'seller_456'
            },
            {
              'id' => 'item_2',
              'name' => 'Product B',
              'amount' => 20_000,
              'payment_type' => 2,
              'buyer_id' => 'buyer_789',
              'seller_id' => 'seller_012'
            }
          ],
          'meta' => {
            'total' => 2,
            'limit' => 10,
            'offset' => 0
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.list
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the item data' do
        response = item_resource.list
        expect(response.data).to eq(item_list_data['items'])
      end

      it 'returns the metadata' do
        response = item_resource.list
        expect(response.meta).to eq(item_list_data['meta'])
      end
    end

    context 'with custom pagination' do
      before do
        stubs.get('/items') do |env|
          [200, { 'Content-Type' => 'application/json' }, item_list_data] if env.params['limit'] == '20'
        end
      end

      let(:item_list_data) do
        {
          'items' => [],
          'meta' => { 'total' => 0, 'limit' => 20, 'offset' => 10 }
        }
      end

      it 'accepts custom limit and offset' do
        response = item_resource.list(limit: 20, offset: 10)
        expect(response.success?).to be true
      end
    end

    context 'with search parameter' do
      before do
        stubs.get('/items') do |env|
          [200, { 'Content-Type' => 'application/json' }, search_results] if env.params['search'] == 'product'
        end
      end

      let(:search_results) do
        {
          'items' => [
            {
              'id' => 'item_1',
              'name' => 'Product A',
              'description' => 'Premium product',
              'amount' => 10_000
            }
          ],
          'meta' => { 'total' => 1, 'limit' => 10, 'offset' => 0 }
        }
      end

      it 'accepts search parameter' do
        response = item_resource.list(search: 'product')
        expect(response.success?).to be true
        expect(response.data.length).to eq(1)
      end
    end

    context 'with date filters' do
      before do
        stubs.get('/items') do |env|
          if env.params['created_after'] && env.params['created_before']
            [200, { 'Content-Type' => 'application/json' }, filtered_results]
          end
        end
      end

      let(:filtered_results) do
        {
          'items' => [
            {
              'id' => 'item_1',
              'name' => 'Recent Item',
              'amount' => 10_000,
              'created_at' => '2024-06-15T10:00:00Z'
            }
          ],
          'meta' => { 'total' => 1, 'limit' => 10, 'offset' => 0 }
        }
      end

      it 'accepts created_after and created_before parameters' do
        response = item_resource.list(
          created_after: '2024-01-01T00:00:00Z',
          created_before: '2024-12-31T23:59:59Z'
        )
        expect(response.success?).to be true
        expect(response.data.length).to eq(1)
      end
    end
  end

  describe '#show' do
    context 'when item exists' do
      before do
        stubs.get('/items/item_123') do
          [200, { 'Content-Type' => 'application/json' }, item_detail]
        end
      end

      let(:item_detail) do
        {
          'items' => {
            'id' => 'item_123',
            'name' => 'Test Product',
            'amount' => 15_000,
            'payment_type' => 2,
            'buyer_id' => 'buyer_123',
            'seller_id' => 'seller_456',
            'description' => 'Test description'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the item details' do
        response = item_resource.show('item_123')
        expect(response.data['id']).to eq('item_123')
        expect(response.data['name']).to eq('Test Product')
      end
    end

    context 'when item does not exist' do
      before do
        stubs.get('/items/item_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Item not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { item_resource.show('item_123') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { item_resource.show('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { item_resource.show(nil) }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#create' do
    let(:base_params) do
      {
        name: 'Test Product',
        amount: 10_000,
        payment_type: 2,
        buyer_id: 'buyer_123',
        seller_id: 'seller_456'
      }
    end

    context 'when creating an item successfully' do
      let(:created_response) do
        {
          'items' => base_params.transform_keys(&:to_s).merge('id' => 'item_new')
        }
      end

      before do
        stubs.post('/items') do |env|
          body = JSON.parse(env.body)
          [201, { 'Content-Type' => 'application/json' }, created_response] if body['name'] == 'Test Product'
        end
      end

      it 'returns the correct response type' do
        response = item_resource.create(**base_params)
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'returns the created item with correct data' do
        response = item_resource.create(**base_params)
        expect(response.data['id']).to eq('item_new')
        expect(response.data['name']).to eq(base_params[:name])
        expect(response.data['amount']).to eq(base_params[:amount])
      end
    end

    context 'when required fields are missing' do
      it 'raises a ValidationError for missing name' do
        params = base_params.except(:name)
        expect { item_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*name/
        )
      end

      it 'raises a ValidationError for missing amount' do
        params = base_params.except(:amount)
        expect { item_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*amount/
        )
      end

      it 'raises a ValidationError for missing payment_type' do
        params = base_params.except(:payment_type)
        expect { item_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*payment_type/
        )
      end

      it 'raises a ValidationError for missing buyer_id' do
        params = base_params.except(:buyer_id)
        expect { item_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*buyer_id/
        )
      end

      it 'raises a ValidationError for missing seller_id' do
        params = base_params.except(:seller_id)
        expect { item_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*seller_id/
        )
      end
    end

    context 'when amount is invalid' do
      it 'raises a ValidationError for negative amount' do
        params = base_params.merge(amount: -100)
        expect { item_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /amount must be a positive integer/)
      end

      it 'raises a ValidationError for zero amount' do
        params = base_params.merge(amount: 0)
        expect { item_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /amount must be a positive integer/)
      end

      it 'raises a ValidationError for non-integer amount' do
        params = base_params.merge(amount: 'not_a_number')
        expect { item_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /amount must be a positive integer/)
      end
    end

    context 'when payment_type is invalid' do
      it 'raises a ValidationError for invalid payment_type' do
        params = base_params.merge(payment_type: 10)
        expect { item_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /payment_type must be between 1 and 7/)
      end
    end
  end

  describe '#update' do
    context 'when successful' do
      before do
        stubs.patch('/items/item_123') do |env|
          body = JSON.parse(env.body)
          [200, { 'Content-Type' => 'application/json' }, updated_response] if body['name'] == 'Updated Product'
        end
      end

      let(:updated_response) do
        {
          'items' => {
            'id' => 'item_123',
            'name' => 'Updated Product',
            'amount' => 12_000,
            'description' => 'Updated description'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.update('item_123', name: 'Updated Product', amount: 12_000)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the updated item data' do
        response = item_resource.update('item_123', name: 'Updated Product', amount: 12_000)
        expect(response.data['name']).to eq('Updated Product')
        expect(response.data['amount']).to eq(12_000)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect do
          item_resource.update('', name: 'Updated Product')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end

    context 'when no update parameters provided' do
      it 'raises a ValidationError' do
        expect do
          item_resource.update('item_123')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /At least one attribute/)
      end
    end
  end

  describe '#delete' do
    context 'when successful' do
      before do
        stubs.delete('/items/item_123') do
          [204, { 'Content-Type' => 'application/json' }, {}]
        end
      end

      it 'returns the correct response type' do
        response = item_resource.delete('item_123')
        expect(response).to be_a(ZaiPayment::Response)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.delete('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#show_seller' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/sellers') do
          [200, { 'Content-Type' => 'application/json' }, seller_data]
        end
      end

      let(:seller_data) do
        {
          'users' => {
            'id' => 'seller_456',
            'email' => 'seller@example.com',
            'first_name' => 'Jane',
            'last_name' => 'Smith'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show_seller('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the seller details' do
        response = item_resource.show_seller('item_123')
        expect(response.data['id']).to eq('seller_456')
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.show_seller('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#show_buyer' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/buyers') do
          [200, { 'Content-Type' => 'application/json' }, buyer_data]
        end
      end

      let(:buyer_data) do
        {
          'users' => {
            'id' => 'buyer_123',
            'email' => 'buyer@example.com',
            'first_name' => 'John',
            'last_name' => 'Doe'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show_buyer('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the buyer details' do
        response = item_resource.show_buyer('item_123')
        expect(response.data['id']).to eq('buyer_123')
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.show_buyer('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#show_fees' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/fees') do
          [200, { 'Content-Type' => 'application/json' }, fees_data]
        end
      end

      let(:fees_data) do
        {
          'fees' => [
            { 'id' => 'fee_1', 'amount' => 500, 'name' => 'Processing Fee' },
            { 'id' => 'fee_2', 'amount' => 300, 'name' => 'Service Fee' }
          ]
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show_fees('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the fees details' do
        response = item_resource.show_fees('item_123')
        expect(response.data.length).to eq(2)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.show_fees('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#show_wire_details' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/wire_details') do
          [200, { 'Content-Type' => 'application/json' }, wire_data]
        end
      end

      let(:wire_data) do
        {
          'items' => {
            'wire_details' => {
              'account_number' => '12345678',
              'routing_number' => '987654321',
              'bank_name' => 'Test Bank'
            }
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show_wire_details('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the wire details' do
        response = item_resource.show_wire_details('item_123')
        expect(response.data['wire_details']).to be_a(Hash)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.show_wire_details('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#list_transactions' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/transactions') do |env|
          [200, { 'Content-Type' => 'application/json' }, transactions_data] if env.params['limit'] == '10'
        end
      end

      let(:transactions_data) do
        {
          'transactions' => [
            { 'id' => 'txn_1', 'amount' => 10_000, 'state' => 'completed' },
            { 'id' => 'txn_2', 'amount' => 5000, 'state' => 'pending' }
          ]
        }
      end

      it 'returns the correct response type' do
        response = item_resource.list_transactions('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the transactions data' do
        response = item_resource.list_transactions('item_123')
        expect(response.data.length).to eq(2)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect do
          item_resource.list_transactions('')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#list_batch_transactions' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/batch_transactions') do |env|
          [200, { 'Content-Type' => 'application/json' }, batch_data] if env.params['limit'] == '10'
        end
      end

      let(:batch_data) do
        {
          'batch_transactions' => [
            { 'id' => 'batch_1', 'amount' => 100_000, 'state' => 'completed' }
          ]
        }
      end

      it 'returns the correct response type' do
        response = item_resource.list_batch_transactions('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the batch transactions data' do
        response = item_resource.list_batch_transactions('item_123')
        expect(response.data.length).to eq(1)
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect do
          item_resource.list_batch_transactions('')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#show_status' do
    context 'when successful' do
      before do
        stubs.get('/items/item_123/status') do
          [200, { 'Content-Type' => 'application/json' }, status_data]
        end
      end

      let(:status_data) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'completed',
            'payment_state' => 'paid'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.show_status('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the status details' do
        response = item_resource.show_status('item_123')
        expect(response.data['state']).to eq('completed')
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError' do
        expect { item_resource.show_status('') }.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end
  end

  describe '#make_payment' do
    context 'when successful' do
      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          [200, { 'Content-Type' => 'application/json' }, payment_response] if body['account_id'] == 'account_456'
        end
      end

      let(:payment_response) do
        {
          'items' => {
            'id' => 'item_123',
            'name' => 'Test Product',
            'amount' => 10_000,
            'state' => 'payment_pending',
            'payment_state' => 'processing'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.make_payment('item_123', 'account_456')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the payment details' do
        response = item_resource.make_payment('item_123', 'account_456')
        expect(response.data['id']).to eq('item_123')
        expect(response.data['payment_state']).to eq('processing')
      end
    end

    context 'with optional payment attributes' do
      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          if body['account_id'] == 'account_456' && body['device_id'] == 'device_789'
            [200, { 'Content-Type' => 'application/json' }, payment_response]
          end
        end
      end

      let(:payment_response) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'payment_pending',
            'payment_state' => 'processing'
          }
        }
      end

      it 'includes device_id when provided' do
        response = item_resource.make_payment('item_123', 'account_456', device_id: 'device_789')
        expect(response.success?).to be true
      end
    end

    context 'with ip_address' do
      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          if body['account_id'] == 'account_456' && body['ip_address'] == '192.168.1.1'
            [200, { 'Content-Type' => 'application/json' }, payment_response]
          end
        end
      end

      let(:payment_response) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'payment_pending'
          }
        }
      end

      it 'includes ip_address when provided' do
        response = item_resource.make_payment('item_123', 'account_456', ip_address: '192.168.1.1')
        expect(response.success?).to be true
      end
    end

    context 'with cvv' do
      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          if body['account_id'] == 'account_456' && body['cvv'] == '123'
            [200, { 'Content-Type' => 'application/json' }, payment_response]
          end
        end
      end

      let(:payment_response) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'payment_pending'
          }
        }
      end

      it 'includes cvv when provided' do
        response = item_resource.make_payment('item_123', 'account_456', cvv: '123')
        expect(response.success?).to be true
      end
    end

    context 'with merchant_phone' do
      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          if body['account_id'] == 'account_456' && body['merchant_phone'] == '+1234567890'
            [200, { 'Content-Type' => 'application/json' }, payment_response]
          end
        end
      end

      let(:payment_response) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'payment_pending'
          }
        }
      end

      it 'includes merchant_phone when provided' do
        response = item_resource.make_payment('item_123', 'account_456', merchant_phone: '+1234567890')
        expect(response.success?).to be true
      end
    end

    context 'with all optional attributes' do
      let(:payment_params) do
        { device_id: 'device_789', ip_address: '192.168.1.1', cvv: '123', merchant_phone: '+1234567890' }
      end

      let(:payment_response) do
        { 'items' => { 'id' => 'item_123', 'state' => 'payment_pending', 'payment_state' => 'processing' } }
      end

      before do
        stubs.patch('/items/item_123/make_payment') do |env|
          body = JSON.parse(env.body)
          valid = body['account_id'] == 'account_456' && payment_params.all? { |k, v| body[k.to_s] == v }
          [200, { 'Content-Type' => 'application/json' }, payment_response] if valid
        end
      end

      it 'includes all optional attributes' do
        response = item_resource.make_payment('item_123', 'account_456', **payment_params)
        expect(response.success?).to be true
        expect(response.data['state']).to eq('payment_pending')
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect do
          item_resource.make_payment('', 'account_456')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end

      it 'raises a ValidationError for nil' do
        expect do
          item_resource.make_payment(nil, 'account_456')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end

    context 'when account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect do
          item_resource.make_payment('item_123', '')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect do
          item_resource.make_payment('item_123', nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_id/)
      end
    end

    context 'when payment fails' do
      before do
        stubs.patch('/items/item_123/make_payment') do
          [422, { 'Content-Type' => 'application/json' }, error_response]
        end
      end

      let(:error_response) do
        {
          'errors' => {
            'base' => ['Insufficient funds']
          }
        }
      end

      it 'raises a ValidationError' do
        expect do
          item_resource.make_payment('item_123', 'account_456')
        end.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end

    context 'when account not found' do
      before do
        stubs.patch('/items/item_123/make_payment') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Account not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect do
          item_resource.make_payment('item_123', 'account_456')
        end.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when unauthorized' do
      before do
        stubs.patch('/items/item_123/make_payment') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect do
          item_resource.make_payment('item_123', 'account_456')
        end.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe '#cancel' do
    context 'when successful' do
      before do
        stubs.patch('/items/item_123/cancel') do
          [200, { 'Content-Type' => 'application/json' }, cancel_response]
        end
      end

      let(:cancel_response) do
        {
          'items' => {
            'id' => 'item_123',
            'name' => 'Test Product',
            'amount' => 10_000,
            'state' => 'cancelled',
            'payment_state' => 'cancelled'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.cancel('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the cancelled item data' do
        response = item_resource.cancel('item_123')
        expect(response.data['id']).to eq('item_123')
        expect(response.data['state']).to eq('cancelled')
        expect(response.data['payment_state']).to eq('cancelled')
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect do
          item_resource.cancel('')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end

      it 'raises a ValidationError for nil' do
        expect do
          item_resource.cancel(nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end

    context 'when item not found' do
      before do
        stubs.patch('/items/item_123/cancel') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Item not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect do
          item_resource.cancel('item_123')
        end.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when item cannot be cancelled' do
      before do
        stubs.patch('/items/item_123/cancel') do
          [422, { 'Content-Type' => 'application/json' }, error_response]
        end
      end

      let(:error_response) do
        {
          'errors' => {
            'base' => ['Item cannot be cancelled in current state']
          }
        }
      end

      it 'raises a ValidationError' do
        expect do
          item_resource.cancel('item_123')
        end.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end

    context 'when unauthorized' do
      before do
        stubs.patch('/items/item_123/cancel') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect do
          item_resource.cancel('item_123')
        end.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe '#refund' do
    context 'when successful' do
      before do
        stubs.patch('/items/item_123/refund') do
          [200, { 'Content-Type' => 'application/json' }, refund_response]
        end
      end

      let(:refund_response) do
        {
          'items' => {
            'id' => 'item_123',
            'name' => 'Test Product',
            'amount' => 10_000,
            'state' => 'refunded',
            'payment_state' => 'refunded'
          }
        }
      end

      it 'returns the correct response type' do
        response = item_resource.refund('item_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the refunded item data' do
        response = item_resource.refund('item_123')
        expect(response.data['id']).to eq('item_123')
        expect(response.data['state']).to eq('refunded')
        expect(response.data['payment_state']).to eq('refunded')
      end
    end

    context 'with optional parameters' do
      before do
        stubs.patch('/items/item_123/refund') do
          [200, { 'Content-Type' => 'application/json' }, refund_response]
        end
      end

      let(:refund_response) do
        {
          'items' => {
            'id' => 'item_123',
            'state' => 'refunded',
            'payment_state' => 'refunded'
          }
        }
      end

      it 'accepts refund_amount parameter' do
        response = item_resource.refund('item_123', refund_amount: 5000)
        expect(response.success?).to be true
      end

      it 'accepts refund_message parameter' do
        response = item_resource.refund('item_123', refund_message: 'Customer requested refund')
        expect(response.success?).to be true
      end

      it 'accepts account_id parameter' do
        response = item_resource.refund('item_123', account_id: 'account_789')
        expect(response.success?).to be true
      end

      it 'accepts all optional parameters' do
        response = item_resource.refund(
          'item_123',
          refund_amount: 5000,
          refund_message: 'Partial refund for shipping',
          account_id: 'account_789'
        )
        expect(response.success?).to be true
      end
    end

    context 'when item_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect do
          item_resource.refund('')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end

      it 'raises a ValidationError for nil' do
        expect do
          item_resource.refund(nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /item_id/)
      end
    end

    context 'when item not found' do
      before do
        stubs.patch('/items/item_123/refund') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Item not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect do
          item_resource.refund('item_123')
        end.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when item cannot be refunded' do
      before do
        stubs.patch('/items/item_123/refund') do
          [422, { 'Content-Type' => 'application/json' }, error_response]
        end
      end

      let(:error_response) do
        {
          'errors' => {
            'base' => ['Item cannot be refunded in current state']
          }
        }
      end

      it 'raises a ValidationError' do
        expect do
          item_resource.refund('item_123')
        end.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end

    context 'when refund amount is invalid' do
      before do
        stubs.patch('/items/item_123/refund') do
          [422, { 'Content-Type' => 'application/json' }, error_response]
        end
      end

      let(:error_response) do
        {
          'errors' => {
            'refund_amount' => ['Refund amount exceeds item amount']
          }
        }
      end

      it 'raises a ValidationError' do
        expect do
          item_resource.refund('item_123', refund_amount: 999_999)
        end.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end

    context 'when unauthorized' do
      before do
        stubs.patch('/items/item_123/refund') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect do
          item_resource.refund('item_123')
        end.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe 'integration with ZaiPayment module' do
    it 'is accessible through ZaiPayment.items' do
      expect(ZaiPayment.items).to be_a(described_class)
    end
  end
end
