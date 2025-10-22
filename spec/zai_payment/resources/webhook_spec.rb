# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::Webhook do
  let(:config) do
    ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end
  end

  let(:token_provider) do
    instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
  end

  let(:client) { ZaiPayment::Client.new(config: config, token_provider: token_provider) }
  let(:webhook_resource) { described_class.new(client: client) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter :test, stubs
    end
  end

  before do
    allow(client).to receive(:connection).and_return(test_connection)
  end

  after do
    stubs.verify_stubbed_calls
  end

  describe '#list' do
    context 'when successful' do
      let(:webhook_data) do
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

      before do
        stubs.get('/webhooks') do |env|
          expect(env.params['limit']).to eq('10')
          expect(env.params['offset']).to eq('0')
          [200, { 'Content-Type' => 'application/json' }, webhook_data]
        end
      end

      it 'returns a list of webhooks' do
        response = webhook_resource.list

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data).to eq(webhook_data['webhooks'])
        expect(response.meta).to eq(webhook_data['meta'])
      end

      it 'accepts custom limit and offset' do
        stubs.clear
        stubs.get('/webhooks') do |env|
          expect(env.params['limit']).to eq('20')
          expect(env.params['offset']).to eq('10')
          [200, { 'Content-Type' => 'application/json' }, webhook_data]
        end

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
    let(:webhook_id) { 'webhook_123' }
    let(:webhook_data) do
      {
        'id' => webhook_id,
        'url' => 'https://example.com/webhook',
        'object_type' => 'transactions',
        'enabled' => true,
        'description' => 'Test webhook'
      }
    end

    context 'when webhook exists' do
      before do
        stubs.get("/webhooks/#{webhook_id}") do
          [200, { 'Content-Type' => 'application/json' }, webhook_data]
        end
      end

      it 'returns the webhook details' do
        response = webhook_resource.show(webhook_id)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq(webhook_id)
        expect(response.data['url']).to eq('https://example.com/webhook')
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.get("/webhooks/#{webhook_id}") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.show(webhook_id) }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError' do
        expect { webhook_resource.show('') }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
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

    let(:created_webhook) do
      {
        'id' => 'webhook_new',
        'url' => webhook_params[:url],
        'object_type' => webhook_params[:object_type],
        'enabled' => webhook_params[:enabled],
        'description' => webhook_params[:description]
      }
    end

    context 'when successful' do
      before do
        stubs.post('/webhooks') do |env|
          body = JSON.parse(env.body)
          expect(body['url']).to eq(webhook_params[:url])
          expect(body['object_type']).to eq(webhook_params[:object_type])
          expect(body['enabled']).to eq(webhook_params[:enabled])
          [201, { 'Content-Type' => 'application/json' }, created_webhook]
        end
      end

      it 'creates a webhook' do
        response = webhook_resource.create(**webhook_params)

        expect(response).to be_a(ZaiPayment::Response)
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
        expect { webhook_resource.create(**params) }.to raise_error(ZaiPayment::Errors::ValidationError, /valid URL/)
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
    let(:webhook_id) { 'webhook_123' }
    let(:update_params) do
      {
        url: 'https://example.com/new-webhook',
        enabled: false
      }
    end

    let(:updated_webhook) do
      {
        'id' => webhook_id,
        'url' => update_params[:url],
        'object_type' => 'transactions',
        'enabled' => update_params[:enabled]
      }
    end

    context 'when successful' do
      before do
        stubs.patch("/webhooks/#{webhook_id}") do |env|
          body = JSON.parse(env.body)
          expect(body['url']).to eq(update_params[:url])
          expect(body['enabled']).to eq(update_params[:enabled])
          [200, { 'Content-Type' => 'application/json' }, updated_webhook]
        end
      end

      it 'updates the webhook' do
        response = webhook_resource.update(webhook_id, **update_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['url']).to eq(update_params[:url])
        expect(response.data['enabled']).to eq(update_params[:enabled])
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update('', **update_params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when no update parameters provided' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update(webhook_id)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /At least one attribute/)
      end
    end

    context 'when url is invalid' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.update(webhook_id, url: 'invalid-url')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /valid URL/)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.patch("/webhooks/#{webhook_id}") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.update(webhook_id, **update_params) }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#delete' do
    let(:webhook_id) { 'webhook_123' }

    context 'when successful' do
      before do
        stubs.delete("/webhooks/#{webhook_id}") do
          [204, {}, '']
        end
      end

      it 'deletes the webhook' do
        response = webhook_resource.delete(webhook_id)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError' do
        expect { webhook_resource.delete('') }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
        expect { webhook_resource.delete(nil) }.to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.delete("/webhooks/#{webhook_id}") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.delete(webhook_id) }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end
end
