# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::VirtualAccount do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:virtual_account_resource) { described_class.new(client: test_client) }

  let(:test_client) do
    config = ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end

    token_provider = instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
    client = ZaiPayment::Client.new(config: config, token_provider: token_provider, base_endpoint: :va_base)

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
    let(:virtual_accounts_list_data) do
      {
        'virtual_accounts' => [
          {
            'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            'routing_number' => '123456',
            'account_number' => '100000017',
            'wallet_account_id' => 'ae07556e-22ef-11eb-adc1-0242ac120002',
            'user_external_id' => 'ca12346e-22ef-11eb-adc1-0242ac120002',
            'currency' => 'AUD',
            'status' => 'active',
            'created_at' => '2020-04-27T20:28:22.378Z',
            'updated_at' => '2020-04-27T20:28:22.378Z',
            'account_type' => 'NIND',
            'full_legal_account_name' => 'Prop Tech Marketplace',
            'account_name' => 'Real Estate Agency X',
            'aka_names' => ['Realestate agency X'],
            'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
          },
          {
            'id' => 'aaaaaaaa-cccc-dddd-eeee-ffffffffffff',
            'routing_number' => '123456',
            'account_number' => '100000025',
            'currency' => 'AUD',
            'wallet_account_id' => 'ae07556e-22ef-11eb-adc1-0242ac120002',
            'user_external_id' => 'ca12346e-22ef-11eb-adc1-0242ac120002',
            'status' => 'pending_activation',
            'created_at' => '2020-04-27T20:28:22.378Z',
            'updated_at' => '2020-04-27T20:28:22.378Z',
            'account_type' => 'NIND',
            'full_legal_account_name' => 'Prop Tech Marketplace',
            'account_name' => 'Real Estate Agency X',
            'aka_names' => ['Realestate agency X'],
            'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
          }
        ],
        'meta' => {
          'total' => 2
        }
      }
    end

    context 'when virtual accounts exist' do
      before do
        stubs.get('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [200, { 'Content-Type' => 'application/json' }, virtual_accounts_list_data]
        end
      end

      it 'returns the correct response type and list of virtual accounts' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data).to be_an(Array)
      end

      it 'returns correct number of virtual accounts' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        expect(response.data.length).to eq(2)
      end

      it 'returns virtual accounts with correct data' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        first_account = response.data[0]
        expect(first_account['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
        expect(first_account['status']).to eq('active')
        expect(first_account['account_name']).to eq('Real Estate Agency X')
      end

      it 'includes meta information' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        expect(response.meta).to be_a(Hash)
        expect(response.meta['total']).to eq(2)
      end
    end

    context 'when wallet account has no virtual accounts' do
      before do
        stubs.get('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [200, { 'Content-Type' => 'application/json' }, { 'virtual_accounts' => [], 'meta' => { 'total' => 0 } }]
        end
      end

      it 'returns empty array' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data).to eq([])
      end

      it 'returns correct meta total for empty list' do
        response = virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002')

        expect(response.meta['total']).to eq(0)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.list('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.list(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.list('   ') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end

    context 'when wallet account does not exist' do
      before do
        stubs.get('/wallet_accounts/invalid_id/virtual_accounts') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.list('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.get('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002') }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.get('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002') }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.get('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.list('ae07556e-22ef-11eb-adc1-0242ac120002') }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end
  end

  describe '#create' do
    let(:virtual_account_data) do
      {
        'virtual_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'routing_number' => '123456',
          'account_number' => '100000017',
          'currency' => 'AUD',
          'wallet_account_id' => 'ae07556e-22ef-11eb-adc1-0242ac120002',
          'user_external_id' => 'ca12346e-22ef-11eb-adc1-0242ac120002',
          'status' => 'pending_activation',
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'account_type' => 'NIND',
          'full_legal_account_name' => 'Prop Tech Marketplace',
          'account_name' => 'Real Estate Agency X',
          'aka_names' => ['Realestate agency X'],
          'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
        }
      }
    end

    let(:valid_params) do
      {
        account_name: 'Real Estate Agency X',
        aka_names: ['Realestate agency X']
      }
    end

    context 'when successful' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end
      end

      it 'returns the correct response type and creates virtual account' do
        response = virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', **valid_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
      end

      it 'includes account_name and aka_names in response' do
        response = virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', **valid_params)

        expect(response.data['account_name']).to eq('Real Estate Agency X')
        expect(response.data['aka_names']).to eq(['Realestate agency X'])
      end
    end

    context 'with minimal params (only account_name)' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end
      end

      it 'creates virtual account with only account_name' do
        response = virtual_account_resource.create(
          'ae07556e-22ef-11eb-adc1-0242ac120002',
          account_name: 'Real Estate Agency X'
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
      end
    end

    context 'with multiple aka_names' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end
      end

      it 'creates virtual account with multiple aka_names' do
        response = virtual_account_resource.create(
          'ae07556e-22ef-11eb-adc1-0242ac120002',
          account_name: 'Real Estate Agency X',
          aka_names: ['RE Agency', 'Real Estate X', 'Agency X']
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with empty aka_names array' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end
      end

      it 'creates virtual account without aka_names' do
        response = virtual_account_resource.create(
          'ae07556e-22ef-11eb-adc1-0242ac120002',
          account_name: 'Real Estate Agency X',
          aka_names: []
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.create('', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.create(nil, **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.create('   ', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end

    context 'when account_name validation fails' do
      it 'raises error for blank account_name' do
        expect do
          virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', account_name: '')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for nil account_name' do
        expect do
          virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', account_name: nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for whitespace only account_name' do
        expect do
          virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', account_name: '   ')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for account_name longer than 140 characters' do
        long_name = 'A' * 141
        expect do
          virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', account_name: long_name)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name must be 140 characters or less/)
      end

      it 'accepts account_name with exactly 140 characters' do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end

        exact_length_name = 'A' * 140
        response = virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002',
                                                   account_name: exact_length_name)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when aka_names validation fails' do
      it 'raises error for non-array aka_names' do
        expect do
          virtual_account_resource.create(
            'ae07556e-22ef-11eb-adc1-0242ac120002',
            account_name: 'Test',
            aka_names: 'not an array'
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /aka_names must be an array/)
      end

      it 'raises error for more than 3 aka_names' do
        expect do
          virtual_account_resource.create(
            'ae07556e-22ef-11eb-adc1-0242ac120002',
            account_name: 'Test',
            aka_names: ['Name 1', 'Name 2', 'Name 3', 'Name 4']
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /aka_names must contain between 0 and 3 items/)
      end

      it 'accepts exactly 3 aka_names' do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [202, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end

        response = virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002',
                                                   account_name: 'Test',
                                                   aka_names: ['Name 1', 'Name 2', 'Name 3'])

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when wallet account does not exist' do
      before do
        stubs.post('/wallet_accounts/invalid_id/virtual_accounts') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.create('invalid_id', **valid_params) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', **valid_params) }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', **valid_params) }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.post('/wallet_accounts/ae07556e-22ef-11eb-adc1-0242ac120002/virtual_accounts') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.create('ae07556e-22ef-11eb-adc1-0242ac120002', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end
  end
end
