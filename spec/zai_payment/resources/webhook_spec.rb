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

  describe '#list_jobs' do
    let(:webhook_id) { 'webhook_123' }

    context 'when successful' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do |env|
          [200, { 'Content-Type' => 'application/json' }, job_list_data] if env.params['limit'] == '10'
        end
      end

      let(:job_list_data) do
        {
          'jobs' => [
            {
              'id' => 'job_1',
              'status' => 'success',
              'object_id' => 'item_123',
              'created_at' => '2024-01-15T10:30:00Z'
            },
            {
              'id' => 'job_2',
              'status' => 'failed',
              'object_id' => 'item_456',
              'created_at' => '2024-01-15T10:31:00Z'
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
        response = webhook_resource.list_jobs(webhook_id)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the jobs data' do
        response = webhook_resource.list_jobs(webhook_id)
        expect(response.data).to eq(job_list_data['jobs'])
      end

      it 'returns the metadata' do
        response = webhook_resource.list_jobs(webhook_id)
        expect(response.meta).to eq(job_list_data['meta'])
      end
    end

    context 'with custom pagination' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do |env|
          if env.params['limit'] == '50' && env.params['offset'] == '100'
            [200, { 'Content-Type' => 'application/json' }, paginated_data]
          end
        end
      end

      let(:paginated_data) do
        {
          'jobs' => [],
          'meta' => { 'total' => 0, 'limit' => 50, 'offset' => 100 }
        }
      end

      it 'accepts custom limit and offset' do
        response = webhook_resource.list_jobs(webhook_id, limit: 50, offset: 100)
        expect(response.success?).to be true
      end
    end

    context 'with status filter' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do |env|
          [200, { 'Content-Type' => 'application/json' }, filtered_data] if env.params['status'] == 'success'
        end
      end

      let(:filtered_data) do
        {
          'jobs' => [{ 'id' => 'job_1', 'status' => 'success' }],
          'meta' => { 'total' => 1, 'limit' => 10, 'offset' => 0 }
        }
      end

      it 'filters jobs by status' do
        response = webhook_resource.list_jobs(webhook_id, status: 'success')
        expect(response.success?).to be true
        expect(response.data.first['status']).to eq('success')
      end
    end

    context 'with object_id filter' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do |env|
          [200, { 'Content-Type' => 'application/json' }, filtered_data] if env.params['object_id'] == 'item_123'
        end
      end

      let(:filtered_data) do
        {
          'jobs' => [{ 'id' => 'job_1', 'object_id' => 'item_123' }],
          'meta' => { 'total' => 1, 'limit' => 10, 'offset' => 0 }
        }
      end

      it 'filters jobs by object_id' do
        response = webhook_resource.list_jobs(webhook_id, object_id: 'item_123')
        expect(response.success?).to be true
        expect(response.data.first['object_id']).to eq('item_123')
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { webhook_resource.list_jobs('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { webhook_resource.list_jobs(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when status is invalid' do
      it 'raises a ValidationError' do
        expect { webhook_resource.list_jobs(webhook_id, status: 'invalid') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /status must be one of/)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.list_jobs(webhook_id) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when unauthorized' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs") do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { webhook_resource.list_jobs(webhook_id) }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe '#show_job' do
    let(:webhook_id) { 'webhook_123' }
    let(:job_id) { 'job_456' }

    context 'when job exists' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs/#{job_id}") do
          [200, { 'Content-Type' => 'application/json' }, {
            'hashed_payload' => '32187',
            'updated_at' => '2009-11-11T18:00:00+12:00',
            'created_at' => '2021-03-18T05:31:32.867255Z',
            'object_id' => 'buyer-123456',
            'payload' => {
              'accounts' => {
                'account_type_id' => 9100,
                'amount' => 0,
                'uuid' => '6f348690-f2d7-0137-3328-0242ac110003'
              }
            },
            'webhook_uuid' => webhook_id,
            'uuid' => job_id,
            'request_responses' => [
              { 'response_code' => 500, 'message' => '', 'created_at' => '2021-05-24T06:54:32.019211768Z' },
              { 'response_code' => 202, 'message' => '', 'created_at' => '2021-05-24T07:24:34.156212905Z' }
            ],
            'links' => {
              'self' => "/webhooks/#{webhook_id}/jobs/#{job_id}",
              'jobs' => "/webhooks/#{webhook_id}/jobs/"
            }
          }]
        end
      end

      it 'returns the correct response type' do
        response = webhook_resource.show_job(webhook_id, job_id)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the job details' do
        response = webhook_resource.show_job(webhook_id, job_id)
        expect(response.data['uuid']).to eq(job_id)
        expect(response.data['webhook_uuid']).to eq(webhook_id)
        expect(response.data['object_id']).to eq('buyer-123456')
      end

      it 'includes request_responses' do
        response = webhook_resource.show_job(webhook_id, job_id)
        expect(response.data['request_responses']).to be_an(Array)
        expect(response.data['request_responses'].length).to eq(2)
        expect(response.data['request_responses'].last['response_code']).to eq(202)
      end

      it 'includes payload data' do
        response = webhook_resource.show_job(webhook_id, job_id)
        expect(response.data['payload']).to be_a(Hash)
        expect(response.data['payload']['accounts']['account_type_id']).to eq(9100)
      end
    end

    context 'when webhook_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { webhook_resource.show_job('', job_id) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { webhook_resource.show_job(nil, job_id) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /webhook_id/)
      end
    end

    context 'when job_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { webhook_resource.show_job(webhook_id, '') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /job_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { webhook_resource.show_job(webhook_id, nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /job_id/)
      end
    end

    context 'when job does not exist' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs/#{job_id}") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Job not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.show_job(webhook_id, job_id) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when webhook does not exist' do
      before do
        stubs.get("/webhooks/#{webhook_id}/jobs/#{job_id}") do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Webhook not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { webhook_resource.show_job(webhook_id, job_id) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#create_secret_key' do
    let(:secret_key) { 'a' * 32 } # 32 byte secret key

    context 'when successful' do
      before do
        stubs.post('/webhooks/secret_key') do |env|
          body = JSON.parse(env.body)
          [201, { 'Content-Type' => 'application/json' }, { 'secret_key' => body['secret_key'] }] if body['secret_key']
        end
      end

      it 'returns a successful response with the secret key' do
        response = webhook_resource.create_secret_key(secret_key: secret_key)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.data['secret_key']).to eq(secret_key)
      end
    end

    context 'when secret_key is missing' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.create_secret_key(secret_key: nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /secret_key/)
      end
    end

    context 'when secret_key is too short' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.create_secret_key(secret_key: 'short')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /at least 32 bytes/)
      end
    end

    context 'when secret_key contains non-ASCII characters' do
      it 'raises a ValidationError' do
        expect do
          webhook_resource.create_secret_key(secret_key: "#{'a' * 31}日")
        end.to raise_error(ZaiPayment::Errors::ValidationError, /ASCII characters/)
      end
    end
  end

  describe '#generate_signature' do
    let(:payload) { '{"event": "status_updated"}' }
    let(:secret) { 'xPpcHHoAOM' }

    context 'with known values from Zai documentation' do
      it 'generates the correct signature matching Zai example' do
        timestamp = 1_257_894_000
        signature = webhook_resource.generate_signature(payload, secret, timestamp)
        # Expected signature based on HMAC SHA256 calculation
        expect(signature).to eq('MHs6orLEJg1W1wPqkL_8X24UjUVe-ZiAXtk2ICHotuQ')
      end
    end

    context 'with default timestamp' do
      it 'generates a valid signature with current time' do
        signature = webhook_resource.generate_signature(payload, secret)
        expect(signature).to be_a(String)
        expect(signature.length).to be > 0
      end
    end
  end

  describe '#verify_signature' do
    let(:payload) { '{"event": "status_updated"}' }
    let(:secret) { 'xPpcHHoAOM' }

    def generate_valid_header(payload, secret, timestamp)
      signature = webhook_resource.generate_signature(payload, secret, timestamp)
      "t=#{timestamp},v=#{signature}"
    end

    context 'when signature is valid' do
      it 'returns true for valid signature' do
        timestamp = Time.now.to_i
        signature_header = generate_valid_header(payload, secret, timestamp)
        result = webhook_resource.verify_signature(
          payload: payload, signature_header: signature_header, secret_key: secret
        )
        expect(result).to be true
      end
    end

    context 'when signature is invalid' do
      it 'returns false for incorrect signature' do
        timestamp = Time.now.to_i
        invalid_header = "t=#{timestamp},v=invalid_signature"
        result = webhook_resource.verify_signature(
          payload: payload, signature_header: invalid_header, secret_key: secret
        )
        expect(result).to be false
      end
    end

    context 'when timestamp is outside tolerance' do
      it 'raises ValidationError for old timestamp' do
        old_timestamp = Time.now.to_i - 600 # 10 minutes ago
        old_header = generate_valid_header(payload, secret, old_timestamp)
        expect do
          webhook_resource.verify_signature(
            payload: payload, signature_header: old_header, secret_key: secret, tolerance: 300
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /outside tolerance/)
      end
    end

    context 'when signature header is malformed' do
      it 'raises ValidationError for missing timestamp' do
        signature = webhook_resource.generate_signature(payload, secret, Time.now.to_i)
        expect do
          webhook_resource.verify_signature(
            payload: payload, signature_header: "v=#{signature}", secret_key: secret
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /missing or invalid timestamp/)
      end
    end

    context 'when signature header is missing signature' do
      it 'raises ValidationError' do
        timestamp = Time.now.to_i
        expect do
          webhook_resource.verify_signature(
            payload: payload, signature_header: "t=#{timestamp}", secret_key: secret
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /missing signature/)
      end
    end

    context 'with multiple signatures in header' do
      it 'returns true if any signature matches' do
        timestamp = Time.now.to_i
        valid_sig = webhook_resource.generate_signature(payload, secret, timestamp)
        header_with_multiple = "t=#{timestamp},v=invalid_sig1,v=#{valid_sig},v=invalid_sig2"
        result = webhook_resource.verify_signature(
          payload: payload, signature_header: header_with_multiple, secret_key: secret
        )
        expect(result).to be true
      end
    end

    context 'when required parameters are missing' do
      it 'raises ValidationError for missing payload' do
        timestamp = Time.now.to_i
        signature_header = generate_valid_header(payload, secret, timestamp)
        expect do
          webhook_resource.verify_signature(
            payload: nil, signature_header: signature_header, secret_key: secret
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /payload/)
      end
    end
  end
end
