# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe ZaiPayment::Client do
  let(:config) do
    ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
      c.timeout = 15
      c.open_timeout = 10
    end
  end

  let(:token_provider) do
    instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
  end

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:client) do
    described_class.new(config: config, token_provider: token_provider)
  end

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

  describe '#initialize' do
    context 'with explicit config and token_provider' do
      it 'uses the provided config' do
        expect(client.config).to eq(config)
      end

      it 'uses the provided token_provider' do
        expect(client.token_provider).to eq(token_provider)
      end

      it 'sets base_endpoint to nil by default' do
        expect(client.base_endpoint).to be_nil
      end
    end

    context 'with base_endpoint' do
      let(:client_with_endpoint) do
        described_class.new(config: config, token_provider: token_provider, base_endpoint: :core_base)
      end

      it 'sets the base_endpoint' do
        expect(client_with_endpoint.base_endpoint).to eq(:core_base)
      end
    end

    context 'with default config and token_provider' do
      before do
        ZaiPayment.configure do |c|
          c.environment = :prelive
          c.client_id = 'default_client_id'
          c.client_secret = 'default_client_secret'
          c.scope = 'default_scope'
        end
      end

      it 'uses ZaiPayment.config when not provided' do
        default_client = described_class.new
        expect(default_client.config).to eq(ZaiPayment.config)
      end

      it 'uses ZaiPayment.auth when not provided' do
        default_client = described_class.new
        expect(default_client.token_provider).to eq(ZaiPayment.auth)
      end
    end
  end

  describe '#get' do
    context 'when successful' do
      before do
        stubs.get('/test-endpoint') do
          [200, { 'Content-Type' => 'application/json' }, { 'result' => 'success' }]
        end
      end

      it 'returns a Response object' do
        response = client.get('/test-endpoint')
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'includes response data' do
        response = client.get('/test-endpoint')
        expect(response.body).to eq({ 'result' => 'success' })
      end

      it 'has success status' do
        response = client.get('/test-endpoint')
        expect(response.success?).to be true
      end
    end

    context 'with query parameters' do
      before do
        stubs.get('/test-endpoint') do |env|
          if env.params['limit'] == '10' && env.params['offset'] == '0'
            [200, { 'Content-Type' => 'application/json' }, { 'result' => 'success' }]
          end
        end
      end

      it 'passes query parameters' do
        response = client.get('/test-endpoint', params: { limit: '10', offset: '0' })
        expect(response.success?).to be true
      end
    end

    context 'when endpoint returns 404' do
      before do
        stubs.get('/nonexistent') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Not found' }]
        end
      end

      it 'raises NotFoundError' do
        expect { client.get('/nonexistent') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#post' do
    context 'when successful' do
      before do
        stubs.post('/test-endpoint') do |env|
          body = JSON.parse(env.body)
          [201, { 'Content-Type' => 'application/json' }, { 'id' => '123', 'name' => 'test' }] if body['name'] == 'test'
        end
      end

      it 'returns a Response object' do
        response = client.post('/test-endpoint', body: { name: 'test' })
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'includes response data' do
        response = client.post('/test-endpoint', body: { name: 'test' })
        expect(response.body['id']).to eq('123')
      end

      it 'has success status' do
        response = client.post('/test-endpoint', body: { name: 'test' })
        expect(response.success?).to be true
      end
    end

    context 'with empty body' do
      before do
        stubs.post('/test-endpoint') do
          [201, { 'Content-Type' => 'application/json' }, { 'result' => 'created' }]
        end
      end

      it 'does not send body when empty' do
        response = client.post('/test-endpoint')
        expect(response.success?).to be true
      end
    end

    context 'when validation fails' do
      before do
        stubs.post('/test-endpoint') do
          [422, { 'Content-Type' => 'application/json' }, { 'errors' => ['Invalid input'] }]
        end
      end

      it 'raises ValidationError' do
        expect { client.post('/test-endpoint', body: {}) }.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end
  end

  describe '#patch' do
    context 'when successful' do
      before do
        stubs.patch('/test-endpoint/123') do |env|
          body = JSON.parse(env.body)
          if body['name'] == 'updated'
            [200, { 'Content-Type' => 'application/json' }, { 'id' => '123', 'name' => 'updated' }]
          end
        end
      end

      it 'returns a Response object' do
        response = client.patch('/test-endpoint/123', body: { name: 'updated' })
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'includes response data' do
        response = client.patch('/test-endpoint/123', body: { name: 'updated' })
        expect(response.body['name']).to eq('updated')
      end

      it 'has success status' do
        response = client.patch('/test-endpoint/123', body: { name: 'updated' })
        expect(response.success?).to be true
      end
    end

    context 'when resource not found' do
      before do
        stubs.patch('/test-endpoint/999') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Not found' }]
        end
      end

      it 'raises NotFoundError' do
        expect { client.patch('/test-endpoint/999', body: {}) }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#delete' do
    context 'when successful' do
      before do
        stubs.delete('/test-endpoint/123') do
          [204, { 'Content-Type' => 'application/json' }, '']
        end
      end

      it 'returns a Response object' do
        response = client.delete('/test-endpoint/123')
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'has success status' do
        response = client.delete('/test-endpoint/123')
        expect(response.success?).to be true
      end
    end

    context 'when resource not found' do
      before do
        stubs.delete('/test-endpoint/999') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'Not found' }]
        end
      end

      it 'raises NotFoundError' do
        expect { client.delete('/test-endpoint/999') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe 'error handling' do
    context 'when unauthorized' do
      before do
        stubs.get('/test-endpoint') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises UnauthorizedError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when forbidden' do
      before do
        stubs.get('/test-endpoint') do
          [403, { 'Content-Type' => 'application/json' }, { 'error' => 'Forbidden' }]
        end
      end

      it 'raises ForbiddenError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end

    context 'when bad request' do
      before do
        stubs.get('/test-endpoint') do
          [400, { 'Content-Type' => 'application/json' }, { 'error' => 'Bad request' }]
        end
      end

      it 'raises BadRequestError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when rate limited' do
      before do
        stubs.get('/test-endpoint') do
          [429, { 'Content-Type' => 'application/json' }, { 'error' => 'Too many requests' }]
        end
      end

      it 'raises RateLimitError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::RateLimitError)
      end
    end

    context 'when server error' do
      before do
        stubs.get('/test-endpoint') do
          [500, { 'Content-Type' => 'application/json' }, { 'error' => 'Internal server error' }]
        end
      end

      it 'raises ServerError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::ServerError)
      end
    end
  end

  describe 'Faraday error handling' do
    let(:faraday_connection) { Faraday.new }

    before do
      allow(client).to receive(:connection).and_return(faraday_connection)
    end

    context 'when timeout occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Faraday::TimeoutError.new('timeout'))
      end

      it 'raises TimeoutError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::TimeoutError, /timed out/)
      end
    end

    context 'when Net::ReadTimeout occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Net::ReadTimeout.new('Read timeout'))
      end

      it 'raises TimeoutError with descriptive message' do
        expect do
          client.get('/test-endpoint')
        end.to raise_error(ZaiPayment::Errors::TimeoutError, /Request timed out: Net::ReadTimeout/)
      end
    end

    context 'when Net::OpenTimeout occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Net::OpenTimeout.new('Open timeout'))
      end

      it 'raises TimeoutError with descriptive message' do
        expect do
          client.get('/test-endpoint')
        end.to raise_error(ZaiPayment::Errors::TimeoutError, /Request timed out: Net::OpenTimeout/)
      end
    end

    context 'when connection fails' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new('connection failed'))
      end

      it 'raises ConnectionError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::ConnectionError, /Connection failed/)
      end
    end

    context 'when client error occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Faraday::ClientError.new('client error'))
      end

      it 'raises ApiError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::ApiError, /Client error/)
      end
    end

    context 'when other Faraday error occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Faraday::Error.new('generic error'))
      end

      it 'raises ApiError' do
        expect { client.get('/test-endpoint') }.to raise_error(ZaiPayment::Errors::ApiError, /Request failed/)
      end
    end
  end

  describe 'connection configuration' do
    let(:actual_client) do
      described_class.new(config: config, token_provider: token_provider)
    end

    it 'does not set the authorization header in the connection (set per-request)' do
      connection = actual_client.send(:build_connection)
      expect(connection.headers['Authorization']).to be_nil
    end

    it 'sets the content-type header' do
      connection = actual_client.send(:build_connection)
      expect(connection.headers['Content-Type']).to eq('application/json')
    end

    it 'sets the accept header' do
      connection = actual_client.send(:build_connection)
      expect(connection.headers['Accept']).to eq('application/json')
    end

    it 'sets the timeout from config' do
      connection = actual_client.send(:build_connection)
      expect(connection.options.timeout).to eq(15)
    end

    it 'sets the open_timeout from config' do
      connection = actual_client.send(:build_connection)
      expect(connection.options.open_timeout).to eq(10)
    end

    it 'sets the read_timeout from config' do
      config.read_timeout = 25
      connection = actual_client.send(:build_connection)
      expect(connection.options.read_timeout).to eq(25)
    end

    context 'when timeouts are not configured' do
      let(:config_without_timeouts) do
        ZaiPayment::Config.new.tap do |c|
          c.environment = :prelive
          c.client_id = 'test_client_id'
          c.client_secret = 'test_client_secret'
          c.scope = 'test_scope'
          c.timeout = nil
          c.open_timeout = nil
        end
      end

      let(:client_without_timeouts) do
        described_class.new(config: config_without_timeouts, token_provider: token_provider)
      end

      it 'does not set timeout' do
        connection = client_without_timeouts.send(:build_connection)
        expect(connection.options.timeout).to be_nil
      end

      it 'does not set open_timeout' do
        connection = client_without_timeouts.send(:build_connection)
        expect(connection.options.open_timeout).to be_nil
      end
    end
  end

  describe 'base URL determination' do
    context 'when base_endpoint is not specified' do
      let(:actual_client) do
        described_class.new(config: config, token_provider: token_provider)
      end

      it 'defaults to va_base endpoint' do
        base_url = actual_client.send(:base_url)
        expect(base_url).to eq(config.endpoints[:va_base])
      end
    end

    context 'when base_endpoint is :core_base' do
      let(:client_with_core_base) do
        described_class.new(config: config, token_provider: token_provider, base_endpoint: :core_base)
      end

      it 'uses core_base endpoint' do
        base_url = client_with_core_base.send(:base_url)
        expect(base_url).to eq(config.endpoints[:core_base])
      end
    end

    context 'when base_endpoint is :auth_base' do
      let(:client_with_auth_base) do
        described_class.new(config: config, token_provider: token_provider, base_endpoint: :auth_base)
      end

      it 'uses auth_base endpoint' do
        base_url = client_with_auth_base.send(:base_url)
        expect(base_url).to eq(config.endpoints[:auth_base])
      end
    end
  end

  describe 'connection reuse' do
    let(:actual_client) do
      described_class.new(config: config, token_provider: token_provider)
    end

    it 'reuses the same connection instance' do
      connection1 = actual_client.send(:connection)
      connection2 = actual_client.send(:connection)
      expect(connection1).to be(connection2)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
