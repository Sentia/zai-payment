# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::Webhook do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:webhook_resource) { described_class.new(client: test_client) }

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
        stubs.get('/webhooks') do |env|
          [200, { 'Content-Type' => 'application/json' }, webhook_list_data] if env.params['limit'] == '10'
        end
      end

      let(:webhook_list_data) do
        {
          'webhooks' => [
            {
              'id' => 'webhook_1',
              'url' => 'https://example.com/webhook1',
              'object_type' => 'transactions',
              'enabled' => true
            },
            {
              'id' => 'webhook_2',
              'url' => 'https://example.com/webhook2',
              'object_type' => 'items',
              'enabled' => false
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
        response = webhook_resource.list
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the webhook data' do
        response = webhook_resource.list
        expect(response.data).to eq(webhook_list_data['webhooks'])
      end

      it 'returns the metadata' do
        response = webhook_resource.list
        expect(response.meta).to eq(webhook_list_data['meta'])
      end
    end

    context 'with custom pagination' do
      before do
        stubs.get('/webhooks') do |env|
          [200, { 'Content-Type' => 'application/json' }, webhook_list_data] if env.params['limit'] == '20'
        end
      end

      let(:webhook_list_data) do
        {
          'webhooks' => [],
          'meta' => { 'total' => 0, 'limit' => 20, 'offset' => 10 }
        }
      end

      it 'accepts custom limit and offset' do
        response = webhook_resource.list(limit: 20, offset: 10)
        expect(response.success?).to be true
      end
    end

    context 'when unauthorized' do
      before do
        stubs.get('/webhooks') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { webhook_resource.list }.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe '#show' do
    context 'when webhook exists' do
      before do
        stubs.get('/webhooks/webhook_123') do
          [200, { 'Content-Type' => 'application/json' }, webhook_detail]
        end
      end

      let(:webhook_detail) do
        {
          'id' => 'webhook_123',
          'url' => 'https://example.com/webhook',
          'object_type' => 'transactions',
          'enabled' => true,
          'description' => 'Test webhook'
        }
      end

      it 'returns the correct response type' do
        response = webhook_resource.show('webhook_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the webhook details' do
        response = webhook_resource.show('webhook_123')
        expect(response.data['id']).to eq('webhook_123')
        expect(response.data['url']).to eq('https://example.com/webhook')
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.get('/webhooks/webhook_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.show('webhook_123') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { webhook_resource.show('') }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { webhook_resource.show(nil) }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end
  end

  describe '#create' do
    let(:webhook_params) do
      {
        url: 'https://example.com/webhook',
        object_type: 'transactions',
        enabled: true,
        description: 'Test webhook'
      }
    end

    context 'when successful' do
      before do
        stubs.post('/webhooks') do |env|
          body = JSON.parse(env.body)
          if body['url'] == webhook_params[:url] && body['object_type'] == webhook_params[:object_type]
            [201, { 'Content-Type' => 'application/json' }, created_response]
          end
        end
      end

      let(:created_response) do
        {
          'id' => 'webhook_new',
          'url' => webhook_params[:url],
          'object_type' => webhook_params[:object_type],
          'enabled' => webhook_params[:enabled],
          'description' => webhook_params[:description]
        }
      end

      it 'returns the correct response type' do
        response = webhook_resource.create(**webhook_params)
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'returns the created webhook with correct data' do
        response = webhook_resource.create(**webhook_params)
        expect(response.data['id']).to eq('webhook_new')
        expect(response.data['url']).to eq(webhook_params[:url])
      end
    end

    context 'when url is missing' do
      it 'raises a ValidationError' do
        params = webhook_params.except(:url)
        expect { webhook_resource.create(**params) }.to raise_error(ZaiPayment::Errors::ValidationError, /url/)
      end
    end

    context 'when object_type is missing' do
      it 'raises a ValidationError' do
        params = webhook_params.except(:object_type)
        expect { webhook_resource.create(**params) }.to raise_error(ZaiPayment::Errors::ValidationError, /object_type/)
      end
    end

    context 'when url is invalid' do
      it 'raises a ValidationError' do
        params = webhook_params.merge(url: 'not-a-valid-url')
        expect { webhook_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /valid HTTP or HTTPS URL/)
      end
    end

    context 'when API returns validation error' do
      before do
        stubs.post('/webhooks') do
          [422, { 'Content-Type' => 'application/json' }, { 'errors' => ['URL is already taken'] }]
        end
      end

      it 'raises a ValidationError' do
        expect { webhook_resource.create(**webhook_params) }.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end
  end

  describe '#update' do
    context 'when successful' do
      before do
        stubs.patch('/webhooks/webhook_123') do |env|
          body = JSON.parse(env.body)
          if body['url'] == 'https://example.com/new-webhook'
            [200, { 'Content-Type' => 'application/json' }, updated_response]
          end
        end
      end

      let(:updated_response) do
        {
          'id' => 'webhook_123',
          'url' => 'https://example.com/new-webhook',
          'object_type' => 'transactions',
          'enabled' => false
        }
      end

      it 'returns the correct response type' do
        response = webhook_resource.update('webhook_123', url: 'https://example.com/new-webhook', enabled: false)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the updated webhook data' do
        response = webhook_resource.update('webhook_123', url: 'https://example.com/new-webhook', enabled: false)
        expect(response.data['url']).to eq('https://example.com/new-webhook')
        expect(response.data['enabled']).to be(false)
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update('', url: 'https://example.com/webhook')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when no update parameters provided' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update('webhook_123')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /At least one attribute/)
      end
    end

    context 'when url is invalid' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update('webhook_123', url: 'invalid-url')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /valid HTTP or HTTPS URL/)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.patch('/webhooks/webhook_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect do
          webhook_resource.update('webhook_123', enabled: false)
        end.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#delete' do
    context 'when successful' do
      before do
        stubs.delete('/webhooks/webhook_123') do
          [204, {}, '']
        end
      end

      it 'returns a successful response' do
        response = webhook_resource.delete('webhook_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { webhook_resource.delete('') }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { webhook_resource.delete(nil) }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.delete('/webhooks/webhook_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.delete('webhook_123') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end
end
