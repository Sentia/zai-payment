# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::TokenAuth do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:token_auth) { described_class.new(client: test_client) }

  let(:test_client) do
    config = ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end

    token_provider = instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
    client = ZaiPayment::Client.new(config: config, token_provider: token_provider, base_endpoint: :core_base)

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

  describe '#generate' do
    context 'with valid bank token parameters' do
      let(:user_id) { 'seller-68611249' }
      let(:token_type) { 'bank' }

      before do
        stubs.post('/token_auths') do |env|
          body = JSON.parse(env.body)
          if body['token_type'] == 'bank' && body['user_id'] == user_id
            [
              200,
              { 'Content-Type' => 'application/json' },
              {
                'token_auth' => {
                  'token' => 'tok_bank_abc123',
                  'user_id' => user_id,
                  'token_type' => token_type
                }
              }
            ]
          end
        end
      end

      it 'generates a bank token successfully' do
        result = token_auth.generate(user_id: user_id, token_type: token_type)
        expect(result.data['token_auth']['token']).to eq('tok_bank_abc123')
        expect(result.data['token_auth']['user_id']).to eq(user_id)
        expect(result.data['token_auth']['token_type']).to eq(token_type)
      end
    end

    context 'with valid card token parameters' do
      let(:user_id) { 'buyer-12345' }
      let(:token_type) { 'card' }

      before do
        stubs.post('/token_auths') do |env|
          body = JSON.parse(env.body)
          if body['token_type'] == 'card' && body['user_id'] == user_id
            [
              200,
              { 'Content-Type' => 'application/json' },
              {
                'token_auth' => {
                  'token' => 'tok_card_xyz789',
                  'user_id' => user_id,
                  'token_type' => token_type
                }
              }
            ]
          end
        end
      end

      it 'generates a card token successfully' do
        result = token_auth.generate(user_id: user_id, token_type: token_type)
        expect(result.data['token_auth']['token']).to eq('tok_card_xyz789')
        expect(result.data['token_auth']['user_id']).to eq(user_id)
        expect(result.data['token_auth']['token_type']).to eq(token_type)
      end
    end

    context 'with default token_type (bank)' do
      let(:user_id) { 'seller-68611249' }

      before do
        stubs.post('/token_auths') do |env|
          body = JSON.parse(env.body)
          if body['token_type'] == 'bank' && body['user_id'] == user_id
            [
              200,
              { 'Content-Type' => 'application/json' },
              {
                'token_auth' => {
                  'token' => 'tok_bank_default',
                  'user_id' => user_id,
                  'token_type' => 'bank'
                }
              }
            ]
          end
        end
      end

      it 'uses bank as default token_type' do
        result = token_auth.generate(user_id: user_id)
        expect(result.data['token_auth']['token_type']).to eq('bank')
      end
    end

    context 'with invalid parameters' do
      it 'raises error when user_id is nil' do
        expect do
          token_auth.generate(user_id: nil, token_type: 'bank')
        end.to raise_error(ZaiPayment::Errors::ValidationError, 'user_id is required and cannot be blank')
      end

      it 'raises error when user_id is empty string' do
        expect do
          token_auth.generate(user_id: '', token_type: 'bank')
        end.to raise_error(ZaiPayment::Errors::ValidationError, 'user_id is required and cannot be blank')
      end

      it 'raises error when user_id is whitespace' do
        expect do
          token_auth.generate(user_id: '   ', token_type: 'bank')
        end.to raise_error(ZaiPayment::Errors::ValidationError, 'user_id is required and cannot be blank')
      end

      it 'raises error when token_type is invalid' do
        expect do
          token_auth.generate(user_id: 'user-123', token_type: 'invalid')
        end.to raise_error(ZaiPayment::Errors::ValidationError, 'token_type must be one of: bank, card')
      end

      it 'raises error when token_type is empty' do
        expect do
          token_auth.generate(user_id: 'user-123', token_type: '')
        end.to raise_error(ZaiPayment::Errors::ValidationError, 'token_type must be one of: bank, card')
      end
    end

    context 'with case-insensitive token_type' do
      let(:user_id) { 'user-123' }

      before do
        stubs.post('/token_auths') do |env|
          body = JSON.parse(env.body)
          if body['user_id'] == user_id
            [
              200,
              { 'Content-Type' => 'application/json' },
              {
                'token_auth' => {
                  'token' => 'tok_test',
                  'user_id' => user_id,
                  'token_type' => body['token_type']
                }
              }
            ]
          end
        end
      end

      it 'accepts uppercase BANK' do
        result = token_auth.generate(user_id: user_id, token_type: 'BANK')
        expect(result.data['token_auth']['token_type']).to eq('BANK')
      end

      it 'accepts uppercase CARD' do
        result = token_auth.generate(user_id: user_id, token_type: 'CARD')
        expect(result.data['token_auth']['token_type']).to eq('CARD')
      end
    end
  end

  describe '#initialize' do
    it 'accepts a custom client' do
      custom_client = instance_double(ZaiPayment::Client)
      token_auth = described_class.new(client: custom_client)
      expect(token_auth.client).to eq(custom_client)
    end

    it 'creates a default client when none provided' do
      allow(ZaiPayment::Client).to receive(:new).with(base_endpoint: :core_base).and_call_original
      token_auth = described_class.new
      expect(token_auth.client).to be_a(ZaiPayment::Client)
    end
  end

  describe 'constants' do
    it 'defines TOKEN_TYPE_BANK' do
      expect(described_class::TOKEN_TYPE_BANK).to eq('bank')
    end

    it 'defines TOKEN_TYPE_CARD' do
      expect(described_class::TOKEN_TYPE_CARD).to eq('card')
    end

    it 'defines VALID_TOKEN_TYPES' do
      expect(described_class::VALID_TOKEN_TYPES).to eq(%w[bank card])
    end
  end
end
