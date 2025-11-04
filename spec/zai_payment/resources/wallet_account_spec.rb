# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::WalletAccount do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:wallet_account_resource) { described_class.new(client: test_client) }

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
    let(:wallet_account_data) do
      {
        'wallet_accounts' => {
          'id' => '5c1c6b10-4c56-0137-8cd7-0242ac110002',
          'active' => true,
          'created_at' => '2019-04-29T02:42:31.536Z',
          'updated_at' => '2020-05-03T12:01:02.254Z',
          'balance' => 663_337,
          'currency' => 'AUD',
          'links' => {
            'self' => '/transactions/aed45af0-6f63-0138-901c-0a58a9feac03/wallet_accounts',
            'users' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/users',
            'batch_transactions' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/batch_transactions',
            'transactions' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/transactions',
            'bpay_details' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/bpay_details',
            'npp_details' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/npp_details',
            'virtual_accounts' => '/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/virtual_accounts'
          }
        }
      }
    end

    context 'when wallet account exists' do
      before do
        stubs.get('/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002') do
          [200, { 'Content-Type' => 'application/json' }, wallet_account_data]
        end
      end

      it 'returns the correct response type and wallet account details' do
        response = wallet_account_resource.show('5c1c6b10-4c56-0137-8cd7-0242ac110002')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('5c1c6b10-4c56-0137-8cd7-0242ac110002')
      end
    end

    context 'when wallet account does not exist' do
      before do
        stubs.get('/wallet_accounts/invalid_id') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { wallet_account_resource.show('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { wallet_account_resource.show('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { wallet_account_resource.show(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
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
            'self' => '/wallet_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/users',
            'items' => '/users/e6bc0480-57ae-0138-c46e-0a58a9feac03/items'
          }
        }
      }
    end

    context 'when Wallet Account has an associated user' do
      before do
        stubs.get('/wallet_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/users') do
          [200, { 'Content-Type' => 'application/json' }, user_data]
        end
      end

      it 'returns the correct response type and user details' do
        response = wallet_account_resource.show_user('901d8cd0-6af3-0138-967d-0a58a9feac04')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('Seller_1234')
      end
    end

    context 'when Wallet Account does not exist' do
      before do
        stubs.get('/wallet_accounts/invalid_id/users') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { wallet_account_resource.show_user('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { wallet_account_resource.show_user('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { wallet_account_resource.show_user(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end
  end

  describe '#show_npp_details' do
    let(:npp_details_data) do
      {
        'wallet_accounts' => {
          'id' => '5c1c6b10-4c56-0137-8cd7-0242ac110002',
          'npp_details' => {
            'pay_id' => 'npp@assemblypayments.com',
            'marketplace_pay_ids' => [
              {
                'pay_id' => 'npp@assemblypayments.com',
                'type' => 'emal'
              },
              {
                'pay_id' => 'Assembly Payments',
                'type' => 'orgn'
              },
              {
                'pay_id' => 96_637_632_645,
                'type' => 'aubn'
              }
            ],
            'reference' => '100014012148074',
            'amount' => '$0.00',
            'currency' => 'AUD'
          }
        }
      }
    end

    context 'when Wallet Account has NPP details' do
      before do
        stubs.get('/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/npp_details') do
          [200, { 'Content-Type' => 'application/json' }, npp_details_data]
        end
      end

      it 'returns the correct response type and NPP details' do
        response = wallet_account_resource.show_npp_details('5c1c6b10-4c56-0137-8cd7-0242ac110002')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('5c1c6b10-4c56-0137-8cd7-0242ac110002')
      end
    end

    context 'when Wallet Account does not exist' do
      before do
        stubs.get('/wallet_accounts/invalid_id/npp_details') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { wallet_account_resource.show_npp_details('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { wallet_account_resource.show_npp_details('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { wallet_account_resource.show_npp_details(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end
  end

  describe '#show_bpay_details' do
    let(:bpay_details_data) do
      {
        'wallet_accounts' => {
          'id' => '5c1c6b10-4c56-0137-8cd7-0242ac110002',
          'bpay_details' => {
            'biller_code' => '230680',
            'reference' => '100014012148074',
            'amount' => '$0.00',
            'currency' => 'AUD'
          }
        }
      }
    end

    context 'when Wallet Account has BPay details' do
      before do
        stubs.get('/wallet_accounts/5c1c6b10-4c56-0137-8cd7-0242ac110002/bpay_details') do
          [200, { 'Content-Type' => 'application/json' }, bpay_details_data]
        end
      end

      it 'returns the correct response type and BPay details' do
        response = wallet_account_resource.show_bpay_details('5c1c6b10-4c56-0137-8cd7-0242ac110002')

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('5c1c6b10-4c56-0137-8cd7-0242ac110002')
      end
    end

    context 'when Wallet Account does not exist' do
      before do
        stubs.get('/wallet_accounts/invalid_id/bpay_details') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { wallet_account_resource.show_bpay_details('invalid_id') }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { wallet_account_resource.show_bpay_details('') }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { wallet_account_resource.show_bpay_details(nil) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end
  end

  describe '#pay_bill' do
    let(:disbursement_data) do
      {
        'disbursements' => {
          'reference_id' => 'test100',
          'id' => '8a31ebfa-421b-4cbb-9241-632f71b3778a',
          'amount' => 173,
          'currency' => 'AUD',
          'created_at' => '2020-05-09T07:09:03.383Z',
          'updated_at' => '2020-05-09T07:09:04.585Z',
          'state' => 'pending',
          'to' => 'BPay Account',
          'account_name' => 'My Water Company',
          'biller_name' => 'ABC Water',
          'biller_code' => 123_456,
          'crn' => '0987654321',
          'links' => {
            'transactions' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/transactions',
            'wallet_accounts' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/wallet_accounts',
            'bank_accounts' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/bank_accounts',
            'bpay_accounts' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/bpay_accounts',
            'paypal_accounts' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/paypal_accounts',
            'items' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/items',
            'users' => '/disbursements/8a31ebfa-421b-4cbb-9241-632f71b3778a/users'
          }
        }
      }
    end

    let(:valid_params) do
      {
        account_id: 'c1824ad0-73f1-0138-3700-0a58a9feac09',
        amount: 173,
        reference_id: 'test100'
      }
    end

    context 'when successful' do
      before do
        stubs.post('/wallet_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/bill_payment') do
          [201, { 'Content-Type' => 'application/json' }, disbursement_data]
        end
      end

      it 'returns the correct response type and creates disbursement' do
        response = wallet_account_resource.pay_bill('901d8cd0-6af3-0138-967d-0a58a9feac04', **valid_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('8a31ebfa-421b-4cbb-9241-632f71b3778a')
      end
    end

    context 'with optional reference_id' do
      before do
        stubs.post('/wallet_accounts/901d8cd0-6af3-0138-967d-0a58a9feac04/bill_payment') do
          [201, { 'Content-Type' => 'application/json' }, disbursement_data]
        end
      end

      it 'includes reference_id in the request' do
        response = wallet_account_resource.pay_bill('901d8cd0-6af3-0138-967d-0a58a9feac04', **valid_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['reference_id']).to eq('test100')
      end
    end

    context 'when validation fails' do
      it 'raises error when required fields are missing' do
        expect do
          wallet_account_resource.pay_bill('901d8cd0-6af3-0138-967d-0a58a9feac04', account_id: 'test123')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /Missing required fields/)
      end

      it 'raises error for invalid amount' do
        params = valid_params.merge(amount: -100)
        expect { wallet_account_resource.pay_bill('901d8cd0-6af3-0138-967d-0a58a9feac04', **params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /amount must be a positive integer/)
      end

      it 'raises error for reference_id with single quote' do
        params = valid_params.merge(reference_id: "test'100")
        expect { wallet_account_resource.pay_bill('901d8cd0-6af3-0138-967d-0a58a9feac04', **params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /reference_id cannot contain single quote/)
      end
    end

    context 'when wallet_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { wallet_account_resource.pay_bill('', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { wallet_account_resource.pay_bill(nil, **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /wallet_account_id/)
      end
    end

    context 'when wallet account does not exist' do
      before do
        stubs.post('/wallet_accounts/invalid_id/bill_payment') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { wallet_account_resource.pay_bill('invalid_id', **valid_params) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end
end
