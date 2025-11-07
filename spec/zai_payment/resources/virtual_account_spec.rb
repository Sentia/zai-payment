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

  describe '#show' do
    let(:virtual_account_data) do
      {
        'virtual_accounts' => {
          'id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'routing_number' => '123456',
          'account_number' => '100000017',
          'currency' => 'AUD',
          'user_external_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'wallet_account_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'status' => 'active',
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'account_type' => 'NIND',
          'full_legal_account_name' => 'Prop Tech Marketplace',
          'account_name' => 'Real Estate Agency X',
          'aka_names' => ['Realestate Agency X', 'Realestate Agency X of PropTech Marketplace'],
          'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
        }
      }
    end

    context 'when virtual account exists' do
      before do
        stubs.get('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc') do
          [200, { 'Content-Type' => 'application/json' }, virtual_account_data]
        end
      end

      it 'returns the correct response type and virtual account details' do
        response = virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end

      it 'returns virtual account with correct details' do
        response = virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

        expect(response.data['account_name']).to eq('Real Estate Agency X')
        expect(response.data['status']).to eq('active')
        expect(response.data['currency']).to eq('AUD')
      end

      it 'includes banking details' do
        response = virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

        expect(response.data['routing_number']).to eq('123456')
        expect(response.data['account_number']).to eq('100000017')
      end

      it 'includes aka_names array' do
        response = virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')

        expect(response.data['aka_names']).to be_an(Array)
        expect(response.data['aka_names'].length).to eq(2)
      end
    end

    context 'when virtual_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.show('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.show(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.show('   ') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end
    end

    context 'when virtual account does not exist' do
      before do
        stubs.get('/virtual_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.show('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.get('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc') }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.get('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc') }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.get('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.show('46deb476-c1a6-41eb-8eb7-26a695bbe5bc') }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end
  end

  describe '#update_aka_names' do
    let(:updated_virtual_account_data) do
      {
        'virtual_accounts' => {
          'id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'routing_number' => '123456',
          'account_number' => '100000017',
          'currency' => 'AUD',
          'user_external_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'wallet_account_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'status' => 'active',
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'account_type' => 'NIND',
          'full_legal_account_name' => 'Prop Tech Marketplace',
          'account_name' => 'Real Estate Agency X',
          'aka_names' => ['Updated Name 1', 'Updated Name 2'],
          'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
        }
      }
    end

    context 'when successful' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [200, { 'Content-Type' => 'application/json' }, updated_virtual_account_data]
        end
      end

      it 'returns the correct response type and updates aka_names' do
        response = virtual_account_resource.update_aka_names(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          ['Updated Name 1', 'Updated Name 2']
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end

      it 'returns updated aka_names' do
        response = virtual_account_resource.update_aka_names(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          ['Updated Name 1', 'Updated Name 2']
        )

        expect(response.data['aka_names']).to eq(['Updated Name 1', 'Updated Name 2'])
      end
    end

    context 'with empty aka_names array' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [200, { 'Content-Type' => 'application/json' },
           { 'virtual_accounts' => updated_virtual_account_data['virtual_accounts'].merge('aka_names' => []) }]
        end
      end

      it 'clears all aka_names' do
        response = virtual_account_resource.update_aka_names(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          []
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['aka_names']).to eq([])
      end
    end

    context 'with single aka_name' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          updated_data = updated_virtual_account_data['virtual_accounts'].merge('aka_names' => ['Single Name'])
          [200, { 'Content-Type' => 'application/json' }, { 'virtual_accounts' => updated_data }]
        end
      end

      it 'updates to single aka_name' do
        response = virtual_account_resource.update_aka_names(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          ['Single Name']
        )

        expect(response.data['aka_names']).to eq(['Single Name'])
      end
    end

    context 'with maximum 3 aka_names' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [200, { 'Content-Type' => 'application/json' },
           { 'virtual_accounts' => updated_virtual_account_data['virtual_accounts']
             .merge('aka_names' => ['Name 1', 'Name 2', 'Name 3']) }]
        end
      end

      it 'updates to 3 aka_names' do
        response = virtual_account_resource.update_aka_names(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          ['Name 1', 'Name 2', 'Name 3']
        )

        expect(response.data['aka_names'].length).to eq(3)
      end
    end

    context 'when virtual_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.update_aka_names('', ['Name']) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.update_aka_names(nil, ['Name']) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.update_aka_names('   ', ['Name']) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end
    end

    context 'when aka_names validation fails' do
      it 'raises error for non-array aka_names' do
        expect do
          virtual_account_resource.update_aka_names('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'not an array')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /aka_names must be an array/)
      end

      it 'raises error for more than 3 aka_names' do
        expect do
          virtual_account_resource.update_aka_names(
            '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
            ['Name 1', 'Name 2', 'Name 3', 'Name 4']
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /aka_names must contain between 0 and 3 items/)
      end
    end

    context 'when virtual account does not exist' do
      before do
        stubs.patch('/virtual_accounts/invalid_id/aka_names') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.update_aka_names('invalid_id', ['Name']) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.update_aka_names('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', ['Name']) }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.update_aka_names('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', ['Name']) }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/aka_names') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.update_aka_names('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', ['Name']) }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end
  end

  describe '#update_account_name' do
    let(:updated_account_data) do
      {
        'virtual_accounts' => {
          'id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'routing_number' => '123456',
          'account_number' => '100000017',
          'currency' => 'AUD',
          'user_external_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'wallet_account_id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'status' => 'active',
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'account_type' => 'NIND',
          'full_legal_account_name' => 'Prop Tech Marketplace',
          'account_name' => 'Updated Account Name',
          'aka_names' => ['Realestate Agency X'],
          'merchant_id' => '46deb476c1a641eb8eb726a695bbe5bc'
        }
      }
    end

    context 'when successful' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/account_name') do
          [202, { 'Content-Type' => 'application/json' }, updated_account_data]
        end
      end

      it 'returns the correct response type and updates account_name' do
        response = virtual_account_resource.update_account_name(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'Updated Account Name'
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end

      it 'returns updated account_name' do
        response = virtual_account_resource.update_account_name(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'Updated Account Name'
        )

        expect(response.data['account_name']).to eq('Updated Account Name')
      end
    end

    context 'with exactly 140 characters' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/account_name') do
          long_name = 'A' * 140
          updated_data = updated_account_data['virtual_accounts'].merge('account_name' => long_name)
          [202, { 'Content-Type' => 'application/json' }, { 'virtual_accounts' => updated_data }]
        end
      end

      it 'accepts account_name with 140 characters' do
        response = virtual_account_resource.update_account_name(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'A' * 140
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['account_name'].length).to eq(140)
      end
    end

    context 'when virtual_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.update_account_name('', 'New Name') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.update_account_name(nil, 'New Name') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.update_account_name('   ', 'New Name') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end
    end

    context 'when account_name validation fails' do
      it 'raises error for blank account_name' do
        expect do
          virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', '')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for nil account_name' do
        expect do
          virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for whitespace only account_name' do
        expect do
          virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', '   ')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name cannot be blank/)
      end

      it 'raises error for account_name longer than 140 characters' do
        long_name = 'A' * 141
        expect do
          virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', long_name)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /account_name must be 140 characters or less/)
      end
    end

    context 'when virtual account does not exist' do
      before do
        stubs.patch('/virtual_accounts/invalid_id/account_name') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.update_account_name('invalid_id', 'New Name') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/account_name') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'New Name') }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/account_name') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'New Name') }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/account_name') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.update_account_name('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'New Name') }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end
  end

  describe '#update_status' do
    let(:status_update_response_data) do
      {
        'id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
        'message' => 'Virtual Account update has been accepted for processing',
        'links' => {
          'self' => '/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc'
        }
      }
    end

    context 'when successful' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/status') do
          [202, { 'Content-Type' => 'application/json' }, status_update_response_data]
        end
      end

      it 'returns the correct response type' do
        response = virtual_account_resource.update_status(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'closed'
        )

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the status update acceptance message' do
        response = virtual_account_resource.update_status(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'closed'
        )

        expect(response.data['id']).to eq('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
        expect(response.data['message']).to eq('Virtual Account update has been accepted for processing')
      end

      it 'includes links in response' do
        response = virtual_account_resource.update_status(
          '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'closed'
        )

        expect(response.data['links']).to be_a(Hash)
        expect(response.data['links']['self']).to eq('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end
    end

    context 'when virtual_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { virtual_account_resource.update_status('', 'closed') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { virtual_account_resource.update_status(nil, 'closed') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { virtual_account_resource.update_status('   ', 'closed') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end
    end

    context 'when status validation fails' do
      it 'raises error for blank status' do
        expect do
          virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', '')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /status cannot be blank/)
      end

      it 'raises error for nil status' do
        expect do
          virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', nil)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /status cannot be blank/)
      end

      it 'raises error for whitespace only status' do
        expect do
          virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', '   ')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /status cannot be blank/)
      end

      it 'raises error for invalid status value' do
        expect do
          virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'active')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /status must be 'closed'/)
      end

      it 'raises error for invalid status value with descriptive message' do
        expect do
          virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'pending')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /status must be 'closed', got 'pending'/)
      end
    end

    context 'when virtual account does not exist' do
      before do
        stubs.patch('/virtual_accounts/invalid_id/status') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { virtual_account_resource.update_status('invalid_id', 'closed') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/status') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'closed') }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/status') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'closed') }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.patch('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/status') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { virtual_account_resource.update_status('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', 'closed') }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
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
