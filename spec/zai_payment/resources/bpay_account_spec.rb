# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::BpayAccount do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:bpay_account_resource) { described_class.new(client: test_client) }

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
    let(:bpay_account_data) do
      {
        'bpay_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'active' => true,
          'created_at' => '2020-04-03T07:59:00.379Z',
          'updated_at' => '2020-04-03T07:59:00.379Z',
          'verification_status' => 'not_verified',
          'currency' => 'AUD',
          'bpay_details' => {
            'account_name' => 'My Water Bill Company',
            'biller_code' => 123_456,
            'biller_name' => 'ABC Water',
            'crn' => 987_654_321
          },
          'links' => {
            'self' => '/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            'users' => '/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users'
          }
        }
      }
    end

    context 'when BPay account exists' do
      before do
        stubs.get('/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') do
          [200, { 'Content-Type' => 'application/json' }, bpay_account_data]
        end
      end

      it 'returns the correct response type and BPay account details' do
        response = bpay_account_resource.show('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
      end
    end

    context 'when BPay account does not exist' do
      before do
        stubs.get('/bpay_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bpay_account_resource.show('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when bpay_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bpay_account_resource.show('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { bpay_account_resource.show(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end
    end
  end

  describe '#redact' do
    context 'when successful' do
      before do
        stubs.delete('/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') do
          [200, { 'Content-Type' => 'application/json' }, { 'bpay_account' => 'Successfully redacted' }]
        end
      end

      it 'returns the correct response type' do
        response = bpay_account_resource.redact('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when bpay_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bpay_account_resource.redact('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { bpay_account_resource.redact(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end
    end

    context 'when BPay account does not exist' do
      before do
        stubs.delete('/bpay_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bpay_account_resource.redact('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe '#show_user' do
    let(:user_data) do
      {
        'users' => {
          'created_at' => '2020-04-03T07:59:00.379Z',
          'updated_at' => '2020-04-03T07:59:00.379Z',
          'id' => 'Seller_1234',
          'full_name' => 'Samuel Seller',
          'email' => 'sam@example.com',
          'mobile' => 69_543_131,
          'first_name' => 'Samuel',
          'last_name' => 'Seller',
          'custom_descriptor' => 'Sam Garden Jobs',
          'location' => 'AUS',
          'verification_state' => 'pending',
          'held_state' => false,
          'roles' => ['customer'],
          'links' => {
            'self' => '/bpay_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/users',
            'items' => '/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/items'
          }
        }
      }
    end

    context 'when BPay account has an associated user' do
      before do
        stubs.get('/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users') do
          [200, { 'Content-Type' => 'application/json' }, user_data]
        end
      end

      it 'returns the correct response type and user details' do
        response = bpay_account_resource.show_user('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('Seller_1234')
      end
    end

    context 'when BPay account does not exist' do
      before do
        stubs.get('/bpay_accounts/invalid_id/users') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { bpay_account_resource.show_user('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when bpay_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { bpay_account_resource.show_user('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { bpay_account_resource.show_user(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_account_id/)
      end
    end
  end

  describe '#create' do
    let(:bpay_account_data) do
      {
        'bpay_accounts' => {
          'id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'created_at' => '2020-04-03T07:59:00.379Z',
          'updated_at' => '2020-04-03T07:59:00.379Z',
          'active' => true,
          'verification_status' => 'not_verified',
          'currency' => 'AUD',
          'bpay_details' => {
            'account_name' => 'My Water Bill Company',
            'biller_code' => 123_456,
            'biller_name' => 'ABC Water',
            'crn' => 987_654_321
          },
          'links' => {
            'self' => '/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            'users' => '/bpay_accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/users'
          }
        }
      }
    end

    let(:valid_params) do
      {
        user_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        account_name: 'My Water Bill Company',
        biller_code: 123_456,
        bpay_crn: '987654321'
      }
    end

    context 'when successful' do
      before do
        stubs.post('/bpay_accounts') do
          [201, { 'Content-Type' => 'application/json' }, bpay_account_data]
        end
      end

      it 'returns the correct response type and creates BPay account' do
        response = bpay_account_resource.create(**valid_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
      end
    end

    context 'when validation fails' do
      it 'raises error when required fields are missing' do
        expect do
          bpay_account_resource.create(user_id: 'user_123', account_name: 'Test')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /Missing required fields/)
      end

      it 'raises error for invalid biller_code length' do
        params = valid_params.merge(biller_code: 12)
        expect { bpay_account_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError,
                          /biller_code must be a numeric value with 3 to 10 digits/)
      end

      it 'raises error for invalid bpay_crn length' do
        params = valid_params.merge(bpay_crn: '1')
        expect { bpay_account_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /bpay_crn must contain between 2 and 20 digits/)
      end
    end
  end
end
