# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Config do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default environment to :prelive' do
      expect(config.environment).to eq(:prelive)
    end

    it 'sets client_id to nil' do
      expect(config.client_id).to be_nil
    end

    it 'sets client_secret to nil' do
      expect(config.client_secret).to be_nil
    end

    it 'sets scope to nil' do
      expect(config.scope).to be_nil
    end
  end

  describe '#validate!' do
    context 'when all required fields are present' do
      before do
        config.client_id = 'test_client_id'
        config.client_secret = 'test_client_secret'
        config.scope = 'test_scope'
      end

      it 'does not raise an error' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'when client_id is nil' do
      before do
        config.client_id = nil
        config.client_secret = 'test_client_secret'
        config.scope = 'test_scope'
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'client_id is required'
        )
      end
    end

    context 'when client_id is empty' do
      before do
        config.client_id = ''
        config.client_secret = 'test_client_secret'
        config.scope = 'test_scope'
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'client_id is required'
        )
      end
    end

    context 'when client_secret is nil' do
      before do
        config.client_id = 'test_client_id'
        config.client_secret = nil
        config.scope = 'test_scope'
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'client_secret is required'
        )
      end
    end

    context 'when client_secret is empty' do
      before do
        config.client_id = 'test_client_id'
        config.client_secret = ''
        config.scope = 'test_scope'
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'client_secret is required'
        )
      end
    end

    context 'when scope is nil' do
      before do
        config.client_id = 'test_client_id'
        config.client_secret = 'test_client_secret'
        config.scope = nil
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'scope is required'
        )
      end
    end

    context 'when scope is empty' do
      before do
        config.client_id = 'test_client_id'
        config.client_secret = 'test_client_secret'
        config.scope = ''
      end

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          'scope is required'
        )
      end
    end
  end

  describe '#endpoints' do
    context 'when environment is :prelive' do
      before { config.environment = :prelive }

      it 'returns prelive endpoints' do
        expect(config.endpoints).to eq(
          core_base: 'https://test.api.promisepay.com',
          va_base: 'https://sandbox.au-0000.api.assemblypay.com',
          auth_base: 'https://au-0000.sandbox.auth.assemblypay.com'
        )
      end
    end

    context 'when environment is "prelive" string' do
      before { config.environment = 'prelive' }

      it 'returns prelive endpoints' do
        expect(config.endpoints).to eq(
          core_base: 'https://test.api.promisepay.com',
          va_base: 'https://sandbox.au-0000.api.assemblypay.com',
          auth_base: 'https://au-0000.sandbox.auth.assemblypay.com'
        )
      end
    end

    context 'when environment is :production' do
      before { config.environment = :production }

      it 'returns production endpoints' do
        expect(config.endpoints).to eq(
          core_base: 'https://au-0000.api.assemblypay.com',
          va_base: 'https://secure.api.promisepay.com',
          auth_base: 'https://au-0000.auth.assemblypay.com'
        )
      end
    end

    context 'when environment is "production" string' do
      before { config.environment = 'production' }

      it 'returns production endpoints' do
        expect(config.endpoints).to eq(
          core_base: 'https://au-0000.api.assemblypay.com',
          va_base: 'https://secure.api.promisepay.com',
          auth_base: 'https://au-0000.auth.assemblypay.com'
        )
      end
    end

    context 'when environment is unknown' do
      before { config.environment = :staging }

      it 'raises an error' do
        expect { config.endpoints }.to raise_error(RuntimeError, 'Unknown environment: staging')
      end
    end
  end

  describe 'attr_accessor' do
    it 'allows setting and getting environment' do
      config.environment = :production
      expect(config.environment).to eq(:production)
    end

    it 'allows setting and getting client_id' do
      config.client_id = 'new_client_id'
      expect(config.client_id).to eq('new_client_id')
    end

    it 'allows setting and getting client_secret' do
      config.client_secret = 'new_client_secret'
      expect(config.client_secret).to eq('new_client_secret')
    end

    it 'allows setting and getting scope' do
      config.scope = 'new_scope'
      expect(config.scope).to eq('new_scope')
    end

    it 'allows setting and getting timeout' do
      config.timeout = 30
      expect(config.timeout).to eq(30)
    end

    it 'allows setting and getting open_timeout' do
      config.open_timeout = 10
      expect(config.open_timeout).to eq(10)
    end
  end
end
