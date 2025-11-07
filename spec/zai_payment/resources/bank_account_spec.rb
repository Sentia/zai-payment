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

  describe '#show' do
    let(:bank_account_data) do
      {
        'bank_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'active' => true,
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'verification_status' => 'not_verified',
          'currency' => 'AUD',
          'bank' => {
            'bank_name' => 'Bank of Australia',
            'country' => 'AUS',
            'account_name' => 'Samuel Seller',
            'routing_number' => 'XXXXX3',
            'account_number' => 'XXX234',
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

    context 'when bank account exists' do
      before do
        stubs.get('/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') do
          [200, { 'Content-Type' => 'application/json' }, bank_account_data]
        end
      end

      it 'returns the correct response type and bank account details' do
        response = bank_account_resource.show('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
      end
    end

    context 'with include_decrypted_fields parameter' do
      before do
        stubs.get('/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') do |env|
          if env.params['include_decrypted_fields'] == 'true'
            decrypted_data = bank_account_data.dup
            decrypted_data['bank_accounts']['bank']['account_number'] = '12345678'
            [200, { 'Content-Type' => 'application/json' }, decrypted_data]
          else
            [200, { 'Content-Type' => 'application/json' }, bank_account_data]
          end
        end
      end

      it 'includes decrypted fields when true' do
        response = bank_account_resource.show(
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          include_decrypted_fields: true
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'excludes decrypted fields when false' do
        response = bank_account_resource.show(
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          include_decrypted_fields: false
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.data['bank']['account_number']).to eq('XXX234')
      end
    end

    context 'when bank account does not exist' do
      before do
        stubs.get('/bank_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bank_account_resource.show('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when bank_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bank_account_resource.show('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bank_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { bank_account_resource.show(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bank_account_id/)
      end
    end
  end

  describe '#redact' do
    context 'when successful' do
      before do
        stubs.delete('/bank_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') do
          [200, { 'Content-Type' => 'application/json' }, { 'bank_account' => 'Successfully redacted' }]
        end
      end

      it 'returns the correct response type' do
        response = bank_account_resource.redact('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when bank_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bank_account_resource.redact('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bank_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { bank_account_resource.redact(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bank_account_id/)
      end
    end

    context 'when bank account does not exist' do
      before do
        stubs.delete('/bank_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bank_account_resource.redact('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#validate_routing_number' do
    let(:routing_number_data) do
      {
        'routing_number' => {
          'routing_number' => '122235821',
          'customer_name' => 'US BANK NA',
          'address' => 'EP-MN-WN1A',
          'city' => 'ST. PAUL',
          'state_code' => 'MN',
          'zip' => '55107',
          'zip_extension' => '1419',
          'phone_area_code' => '800',
          'phone_prefix' => '937',
          'phone_suffix' => '631'
        }
      }
    end

    context 'when routing number is valid' do
      before do
        stubs.get('/tools/routing_number') do |env|
          if env.params['routing_number'] == '122235821'
            [200, { 'Content-Type' => 'application/json' }, routing_number_data]
          else
            [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Invalid routing number' }]
          end
        end
      end

      it 'returns the correct response type' do
        response = bank_account_resource.validate_routing_number('122235821')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns routing number details' do
        response = bank_account_resource.validate_routing_number('122235821')

        expect(response.data).to be_a(Hash)
        expect(response.data['routing_number']['routing_number']).to eq('122235821')
      end

      it 'returns city, state, and zip' do
        response = bank_account_resource.validate_routing_number('122235821')

        expect(response.data['routing_number']['customer_name']).to eq('US BANK NA')
        expect(response.data['routing_number']['city']).to eq('ST. PAUL')
        expect(response.data['routing_number']['state_code']).to eq('MN')
      end
    end

    context 'when routing number is invalid' do
      before do
        stubs.get('/tools/routing_number') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Invalid routing number' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bank_account_resource.validate_routing_number('invalid') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when routing_number is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bank_account_resource.validate_routing_number('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /routing_number/)
      end

      it 'raises a ValidationError for nil' do
        expect { bank_account_resource.validate_routing_number(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /routing_number/)
      end
    end
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
