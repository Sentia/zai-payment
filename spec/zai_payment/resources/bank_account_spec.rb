# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::BankAccount do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:bank_account_resource) { described_class.new(client: test_client) }

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

  describe '#create_au' do
    let(:bank_account_data) do
      {
        'bank_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'active' => true,
          'verification_status' => 'not_verified',
          'currency' => 'AUD',
          'bank' => {
            'bank_name' => 'Bank of Australia',
            'country' => 'AUS',
            'account_name' => 'Samuel Seller',
            'routing_number' => 'XXXXX3',
            'account_number' => 'XXX234',
            'iban' => 'null,',
            'swift_code' => 'null,',
            'holder_type' => 'personal',
            'account_type' => 'checking',
            'direct_debit_authority_status' => 'approved'
          },
          'links' => {
            'self' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            'users' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users',
            'direct_debit_authorities' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/direct_debit_authorities'
          }
        }
      }
    end

    let(:valid_au_params) do
      {
        user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        bank_name: 'Bank of Australia',
        account_name: 'Samuel Seller',
        routing_number: '111123',
        account_number: '111234',
        account_type: 'checking',
        holder_type: 'personal',
        country: 'AUS'
      }
    end

    context 'when successful' do
      before do
        stubs.post('/bank_accounts') do
          [201, { 'Content-Type' => 'application/json' }, bank_account_data]
        end
      end

      it 'returns the correct response type and creates bank account' do
        response = bank_account_resource.create_au(**valid_au_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with optional fields' do
      before do
        stubs.post('/bank_accounts') do
          [201, { 'Content-Type' => 'application/json' }, bank_account_data]
        end
      end

      it 'accepts optional payout_currency and currency' do
        response = bank_account_resource.create_au(**valid_au_params, payout_currency: 'AUD', currency: 'AUD')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when validation fails' do
      it 'raises error when required fields are missing' do
        expect do
          bank_account_resource.create_au(user_id: 'user_123', bank_name: 'Bank of Australia')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /Missing required fields/)
      end

      it 'raises error for invalid account_type' do
        params = valid_au_params.merge(account_type: 'invalid')
        expect { bank_account_resource.create_au(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError)
      end

      it 'raises error for invalid holder_type' do
        params = valid_au_params.merge(holder_type: 'invalid')
        expect { bank_account_resource.create_au(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end
  end

  describe '#create_uk' do
    let(:bank_account_data) do
      {
        'bank_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'active' => true,
          'verification_status' => 'not_verified',
          'currency' => 'GBP',
          'bank' => {
            'bank_name' => 'Bank of UK',
            'country' => 'GBR',
            'account_name' => 'Samuel Seller',
            'routing_number' => 'XXXXX3',
            'account_number' => 'XXX234',
            'iban' => 'GB25QHWM02498765432109',
            'swift_code' => 'BUKBGB22',
            'holder_type' => 'personal',
            'account_type' => 'checking',
            'direct_debit_authority_status' => 'approved'
          },
          'links' => {
            'self' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            'users' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users',
            'direct_debit_authorities' => '/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/direct_debit_authorities'
          }
        }
      }
    end

    let(:valid_uk_params) do
      {
        user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        bank_name: 'Bank of UK',
        account_name: 'Samuel Seller',
        routing_number: '111123',
        account_number: '111234',
        account_type: 'checking',
        holder_type: 'personal',
        country: 'GBR',
        iban: 'GB25QHWM02498765432109',
        swift_code: 'BUKBGB22'
      }
    end

    context 'when successful' do
      before do
        stubs.post('/bank_accounts') do
          [201, { 'Content-Type' => 'application/json' }, bank_account_data]
        end
      end

      it 'returns the correct response type and creates bank account' do
        response = bank_account_resource.create_uk(**valid_uk_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with optional fields' do
      before do
        stubs.post('/bank_accounts') do
          [201, { 'Content-Type' => 'application/json' }, bank_account_data]
        end
      end

      it 'accepts optional payout_currency and currency' do
        response = bank_account_resource.create_uk(**valid_uk_params, payout_currency: 'GBP', currency: 'GBP')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when validation fails' do
      it 'raises error when required fields are missing' do
        expect { bank_account_resource.create_uk(user_id: 'user_123', bank_name: 'Bank of UK') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Missing required fields/)
      end

      it 'raises error when UK-specific fields are missing' do
        params = valid_uk_params.except(:iban, :swift_code)
        expect { bank_account_resource.create_uk(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError)
      end

      it 'raises error for invalid country format' do
        params = valid_uk_params.merge(country: 'INVALID')
        expect { bank_account_resource.create_uk(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end
  end
end
