# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe ZaiPayment::Auth::TokenProvider do
  let(:config) do
    instance_double(
      ZaiPayment::Config,
      client_id: 'test_client_id',
      client_secret: 'test_secret',
      scope: 'test_scope',
      endpoints: { auth_base: 'https://auth.example.com' }
    )
  end

  let(:store) { instance_double(ZaiPayment::Auth::TokenStore) }
  let(:provider) { described_class.new(config: config, store: store) }

  describe '#initialize' do
    it 'creates a new provider with config and store' do
      expect(provider).to be_a(described_class)
    end
  end

  describe '#bearer_token' do
    context 'when a valid token exists in the store' do
      let(:valid_token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'cached_token_value',
          expires_at: Time.now + 3600
        )
      end

      before do
        allow(store).to receive(:fetch).and_return(valid_token)
        allow(provider).to receive(:request_token!)
      end

      it 'returns the cached token with Bearer prefix' do
        expect(provider.bearer_token).to eq('Bearer cached_token_value')
      end

      it 'does not request a new token' do
        provider.bearer_token
        expect(provider).not_to have_received(:request_token!)
      end
    end

    context 'when no token exists in the store' do
      let(:new_token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'new_token_value',
          expires_at: Time.now + 3600
        )
      end

      before do
        allow(store).to receive(:fetch).and_return(nil)
        allow(provider).to receive(:request_token!).and_return(new_token)
        allow(store).to receive(:write)
      end

      it 'requests a new token' do
        provider.bearer_token
        expect(provider).to have_received(:request_token!)
      end

      it 'writes the new token to the store' do
        provider.bearer_token
        expect(store).to have_received(:write).with(new_token)
      end

      it 'returns the new token with Bearer prefix' do
        expect(provider.bearer_token).to eq('Bearer new_token_value')
      end
    end

    context 'when the token exists but is expired' do
      let(:expired_token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'expired_token_value',
          expires_at: Time.now - 10
        )
      end

      let(:new_token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'new_token_value',
          expires_at: Time.now + 3600
        )
      end

      before do
        allow(store).to receive(:fetch).and_return(expired_token)
        allow(provider).to receive(:request_token!).and_return(new_token)
        allow(store).to receive(:write)
      end

      it 'requests a new token' do
        provider.bearer_token
        expect(provider).to have_received(:request_token!)
      end

      it 'writes the new token to the store' do
        provider.bearer_token
        expect(store).to have_received(:write).with(new_token)
      end

      it 'returns the new token with Bearer prefix' do
        expect(provider.bearer_token).to eq('Bearer new_token_value')
      end
    end

    context 'when checking for race conditions' do
      before do
        expired_token = ZaiPayment::Auth::TokenStore::Token.new(
          value: 'expired_token_value',
          expires_at: Time.now - 10
        )
        new_token = ZaiPayment::Auth::TokenStore::Token.new(
          value: 'new_token_value',
          expires_at: Time.now + 3600
        )
        # First call returns expired, second call (after mutex) returns valid
        allow(store).to receive(:fetch).and_return(expired_token, new_token)
        allow(provider).to receive(:request_token!)
      end

      it 'double-checks the store after acquiring the mutex' do
        result = provider.bearer_token
        expect(result).to eq('Bearer new_token_value')
      end

      it 'does not request a new token if another thread already refreshed it' do
        provider.bearer_token
        expect(provider).not_to have_received(:request_token!)
      end
    end
  end

  describe '#request_token!' do
    let(:token_response_body) do
      {
        'access_token' => 'new_access_token',
        'expires_in' => 7200,
        'token_type' => 'Bearer'
      }.to_json
    end

    before do
      faraday_connection = instance_double(Faraday::Connection)
      faraday_response = instance_double(Faraday::Response)
      allow(Faraday).to receive(:new).and_return(faraday_connection)
      request_stub = instance_double(Faraday::Request)
      allow(request_stub).to receive(:body=)
      allow(faraday_connection).to receive(:post)
        .and_yield(request_stub)
        .and_return(faraday_response)
      allow(faraday_response).to receive(:body).and_return(token_response_body)
    end

    it 'creates a new token from the API response' do
      token = provider.send(:request_token!)
      expect(token).to be_a(ZaiPayment::Auth::TokenStore::Token)
    end

    it 'sets the correct token value' do
      token = provider.send(:request_token!)
      expect(token.value).to eq('new_access_token')
    end

    it 'sets the expiration time with a 60 second buffer' do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)
      token = provider.send(:request_token!)
      expected_expiration = freeze_time + 7200 - 60
      expect(token.expires_at).to eq(expected_expiration)
    end

    context 'when the API request fails' do
      before do
        faraday_connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(faraday_connection)
        error = Faraday::ConnectionFailed.new('Connection failed')
        allow(faraday_connection).to receive(:post).and_raise(error)
      end

      it 'raises an AuthError' do
        expect { provider.send(:request_token!) }.to raise_error(
          ZaiPayment::Errors::AuthError,
          /Token request failed: Connection failed/
        )
      end
    end

    context 'when the response does not contain an access_token' do
      let(:token_response_body) do
        {
          'expires_in' => 7200,
          'token_type' => 'Bearer'
        }.to_json
      end

      it 'raises an AuthError' do
        expect { provider.send(:request_token!) }.to raise_error(
          ZaiPayment::Errors::AuthError,
          'No access_token found'
        )
      end
    end

    context 'when the response uses "token" instead of "access_token"' do
      let(:token_response_body) do
        {
          'token' => 'alternative_token_value',
          'expires_in' => 3600,
          'token_type' => 'Bearer'
        }.to_json
      end

      it 'extracts the token value correctly' do
        token = provider.send(:request_token!)
        expect(token.value).to eq('alternative_token_value')
      end
    end

    context 'when expires_in is not provided' do
      let(:token_response_body) do
        {
          'access_token' => 'new_access_token',
          'token_type' => 'Bearer'
        }.to_json
      end

      it 'defaults to 3600 seconds' do
        freeze_time = Time.now
        allow(Time).to receive(:now).and_return(freeze_time)
        token = provider.send(:request_token!)
        expected_expiration = freeze_time + 3600 - 60
        expect(token.expires_at).to eq(expected_expiration)
      end
    end
  end

  describe '#perform_token_request' do
    before do
      @faraday_connection = instance_double(Faraday::Connection)
      @faraday_response = instance_double(Faraday::Response)
      @request_stub = instance_double(Faraday::Request)
      allow(Faraday).to receive(:new).and_return(@faraday_connection)
      allow(@faraday_connection).to receive(:post)
        .and_yield(@request_stub)
        .and_return(@faraday_response)
      allow(@request_stub).to receive(:body=)
    end

    it 'makes a POST request to /tokens' do
      provider.send(:perform_token_request)
      expect(@faraday_connection).to have_received(:post).with('/tokens')
    end

    it 'sends grant_type as client_credentials' do
      provider.send(:perform_token_request)
      expect(@request_stub).to have_received(:body=).with(
        hash_including(grant_type: 'client_credentials')
      )
    end

    it 'sends the client_id from config' do
      provider.send(:perform_token_request)
      expect(@request_stub).to have_received(:body=).with(
        hash_including(client_id: 'test_client_id')
      )
    end

    it 'sends the client_secret from config' do
      provider.send(:perform_token_request)
      expect(@request_stub).to have_received(:body=).with(
        hash_including(client_secret: 'test_secret')
      )
    end

    it 'sends the scope from config' do
      provider.send(:perform_token_request)
      expect(@request_stub).to have_received(:body=).with(
        hash_including(scope: 'test_scope')
      )
    end

    it 'returns the response' do
      expect(provider.send(:perform_token_request)).to eq(@faraday_response)
    end
  end

  describe '#connection' do
    it 'creates a Faraday connection' do
      connection = provider.send(:connection)
      expect(connection).to be_a(Faraday::Connection)
    end

    it 'sets the correct base URL' do
      connection = provider.send(:connection)
      expect(connection.url_prefix.to_s).to eq('https://auth.example.com/')
    end

    it 'configures URL encoding for requests' do
      connection = provider.send(:connection)
      expect(connection.builder.handlers).to include(Faraday::Request::UrlEncoded)
    end

    it 'configures JSON response parsing' do
      connection = provider.send(:connection)
      expect(connection.builder.handlers).to include(Faraday::Response::Json)
    end
  end

  describe '#parse_token_response' do
    let(:response_body) do
      {
        'access_token' => 'parsed_token',
        'expires_in' => 1800,
        'token_type' => 'Bearer'
      }.to_json
    end

    let(:response) do
      instance_double(Faraday::Response, body: response_body)
    end

    it 'parses the response and creates a Token' do
      token = provider.send(:parse_token_response, response)
      expect(token).to be_a(ZaiPayment::Auth::TokenStore::Token)
    end

    it 'sets the correct token value' do
      token = provider.send(:parse_token_response, response)
      expect(token.value).to eq('parsed_token')
    end

    it 'calculates expiration time with 60 second buffer' do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)
      token = provider.send(:parse_token_response, response)
      expected_expiration = freeze_time + 1800 - 60
      expect(token.expires_at).to eq(expected_expiration)
    end

    context 'when response body is malformed' do
      let(:response_body) { 'invalid json' }

      it 'raises a JSON parse error' do
        expect do
          provider.send(:parse_token_response, response)
        end.to raise_error(JSON::ParserError)
      end
    end
  end

  describe 'thread safety' do
    let(:mutex) { instance_double(Mutex) }
    let(:new_token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'thread_safe_token',
        expires_at: Time.now + 3600
      )
    end

    before do
      allow(Mutex).to receive(:new).and_return(mutex)
      allow(mutex).to receive(:synchronize).and_yield
      allow(store).to receive(:fetch).and_return(nil)
      allow(store).to receive(:write)
    end

    it 'uses a mutex to prevent race conditions' do
      provider_with_mutex = described_class.new(config: config, store: store)
      allow(provider_with_mutex).to receive(:request_token!).and_return(new_token)
      provider_with_mutex.bearer_token
      expect(mutex).to have_received(:synchronize)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
