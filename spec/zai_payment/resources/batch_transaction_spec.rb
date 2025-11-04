# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::BatchTransaction do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:batch_transaction_resource) { described_class.new(client: test_client, config: test_config) }

  let(:test_config) do
    ZaiPayment::Config.new.tap do |c|
      c.environment = :prelive
      c.client_id = 'test_client_id'
      c.client_secret = 'test_client_secret'
      c.scope = 'test_scope'
    end
  end

  let(:test_client) do
    token_provider = instance_double(ZaiPayment::Auth::TokenProvider, bearer_token: 'Bearer test_token')
    client = ZaiPayment::Client.new(config: test_config, token_provider: token_provider)

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
    context 'with default parameters' do
      before do
        stubs.get('/batch_transactions') do |env|
          [200, { 'Content-Type' => 'application/json' }, list_data] if env.params['limit'] == '10'
        end
      end

      let(:list_data) do
        {
          'batch_transactions' => [
            {
              'id' => 12_484,
              'status' => 12_200,
              'reference_id' => '7190770-1-2908',
              'type' => 'disbursement',
              'type_method' => 'direct_credit'
            }
          ],
          'meta' => { 'limit' => 10, 'offset' => 0, 'total' => 1 }
        }
      end

      it 'returns batch transactions list' do
        response = batch_transaction_resource.list
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.data.first['id']).to eq(12_484)
      end
    end

    context 'with filters' do
      before do
        stubs.get('/batch_transactions') do |env|
          response_data = {
            'batch_transactions' => [],
            'meta' => { 'limit' => 50, 'offset' => 0, 'total' => 0 }
          }
          if env.params['transaction_type'] == 'disbursement'
            [200, { 'Content-Type' => 'application/json' }, response_data]
          end
        end
      end

      it 'accepts valid filters' do
        response = batch_transaction_resource.list(
          transaction_type: 'disbursement',
          direction: 'credit',
          limit: 50
        )
        expect(response).to be_a(ZaiPayment::Response)
      end
    end

    context 'with invalid enum values' do
      it 'raises error for invalid transaction_type' do
        expect do
          batch_transaction_resource.list(transaction_type: 'invalid')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /transaction_type must be one of/)
      end

      it 'raises error for invalid transaction_type_method' do
        expect do
          batch_transaction_resource.list(transaction_type_method: 'invalid')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /transaction_type_method must be one of/)
      end

      it 'raises error for invalid direction' do
        expect do
          batch_transaction_resource.list(direction: 'invalid')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /direction must be one of/)
      end
    end
  end

  describe '#export_transactions' do
    context 'when in prelive environment' do
      before do
        stubs.get('/batch_transactions/export_transactions') do
          [200, { 'Content-Type' => 'application/json' }, export_transactions_data]
        end
      end

      let(:export_transactions_data) do
        {
          'transactions' => [
            {
              'id' => '439970a2-e0a1-418e-aecf-6b519c115c55',
              'batch_id' => 'dabcfd50-bf5a-0138-7b40-0a58a9feac03',
              'status' => 'batched',
              'type' => 'payment_funding',
              'type_method' => 'credit_card'
            }
          ]
        }
      end

      it 'returns the correct response type' do
        response = batch_transaction_resource.export_transactions
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the transaction data' do
        response = batch_transaction_resource.export_transactions
        expect(response.data).to eq(export_transactions_data['transactions'])
      end

      it 'includes batch_id in response' do
        response = batch_transaction_resource.export_transactions
        expect(response.data.first['batch_id']).to eq('dabcfd50-bf5a-0138-7b40-0a58a9feac03')
      end

      it 'includes transaction id in response' do
        response = batch_transaction_resource.export_transactions
        expect(response.data.first['id']).to eq('439970a2-e0a1-418e-aecf-6b519c115c55')
      end
    end

    context 'when not in prelive environment' do
      let(:test_config) do
        ZaiPayment::Config.new.tap do |c|
          c.environment = :production
          c.client_id = 'test_client_id'
          c.client_secret = 'test_client_secret'
          c.scope = 'test_scope'
        end
      end

      it 'raises a configuration error' do
        expect do
          batch_transaction_resource.export_transactions
        end.to raise_error(
          ZaiPayment::Errors::ConfigurationError,
          /Batch transaction endpoints are only available in prelive environment/
        )
      end
    end
  end

  describe '#update_transaction_states' do
    context 'with bank_processing state (12700)' do
      before do
        stubs.patch('/batches/test-batch-id/transaction_states') do |env|
          body = JSON.parse(env.body)
          response_data = {
            'aggregated_jobs_uuid' => 'c1cbc502-9754-42fd-9731-2330ddd7a41f',
            'msg' => '1 jobs have been sent to the queue.',
            'errors' => []
          }
          [200, { 'Content-Type' => 'application/json' }, response_data] if body['state'] == 12_700
        end
      end

      it 'returns successful response with job information' do
        response = batch_transaction_resource.update_transaction_states(
          'test-batch-id', exported_ids: ['id'], state: 12_700
        )
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.body['aggregated_jobs_uuid']).not_to be_nil
      end
    end

    context 'with successful state (12000)' do
      before do
        stubs.patch('/batches/test-batch-id/transaction_states') do |env|
          body = JSON.parse(env.body)
          response_data = {
            'aggregated_jobs_uuid' => 'a2bcd345-6789-42fd-9731-2330ddd7a41f',
            'msg' => '2 jobs have been sent to the queue.',
            'errors' => []
          }
          [200, { 'Content-Type' => 'application/json' }, response_data] if body['state'] == 12_000
        end
      end

      it 'handles multiple transaction ids' do
        response = batch_transaction_resource.update_transaction_states(
          'test-batch-id', exported_ids: %w[id1 id2], state: 12_000
        )
        expect(response.body['msg']).to eq('2 jobs have been sent to the queue.')
      end
    end

    context 'when not in prelive environment' do
      let(:test_config) do
        ZaiPayment::Config.new.tap do |c|
          c.environment = :production
          c.client_id = 'test_client_id'
          c.client_secret = 'test_client_secret'
          c.scope = 'test_scope'
        end
      end

      it 'raises a configuration error' do
        expect do
          batch_transaction_resource.update_transaction_states(
            'batch-id', exported_ids: ['id'], state: 12_700
          )
        end.to raise_error(ZaiPayment::Errors::ConfigurationError, /only available in prelive/)
      end
    end

    context 'with invalid parameters' do
      it 'raises an error when batch_id is blank' do
        expect do
          batch_transaction_resource.update_transaction_states(
            '', exported_ids: ['id'], state: 12_700
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /batch_id is required/)
      end

      it 'raises an error when exported_ids is invalid' do
        expect do
          batch_transaction_resource.update_transaction_states(
            'batch-id', exported_ids: [], state: 12_700
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /exported_ids/)
      end

      it 'raises an error when state is invalid' do
        expect do
          batch_transaction_resource.update_transaction_states(
            'batch-id', exported_ids: ['id'], state: 99_999
          )
        end.to raise_error(ZaiPayment::Errors::ValidationError, /state must be/)
      end
    end
  end

  describe '#process_to_bank_processing' do
    before do
      stubs.patch('/batches/test-batch-id/transaction_states') do |env|
        body = JSON.parse(env.body)
        response_data = {
          'aggregated_jobs_uuid' => 'e4fgh567-8901-42fd-9731-2330ddd7a41f',
          'msg' => '1 jobs have been sent to the queue.',
          'errors' => []
        }
        [200, { 'Content-Type' => 'application/json' }, response_data] if body['state'] == 12_700
      end
    end

    it 'calls update_transaction_states with state 12700' do
      response = batch_transaction_resource.process_to_bank_processing(
        'test-batch-id', exported_ids: ['id']
      )
      expect(response).to be_a(ZaiPayment::Response)
      expect(response.body['msg']).to eq('1 jobs have been sent to the queue.')
    end
  end

  describe '#process_to_successful' do
    before do
      stubs.patch('/batches/test-batch-id/transaction_states') do |env|
        body = JSON.parse(env.body)
        response_data = {
          'aggregated_jobs_uuid' => 'f5ghi678-9012-42fd-9731-2330ddd7a41f',
          'msg' => '1 jobs have been sent to the queue.',
          'errors' => []
        }
        [200, { 'Content-Type' => 'application/json' }, response_data] if body['state'] == 12_000
      end
    end

    it 'calls update_transaction_states with state 12000' do
      response = batch_transaction_resource.process_to_successful(
        'test-batch-id', exported_ids: ['id']
      )
      expect(response).to be_a(ZaiPayment::Response)
      expect(response.body['msg']).to eq('1 jobs have been sent to the queue.')
    end
  end

  describe 'integration with ZaiPayment module' do
    before do
      ZaiPayment.configure do |config|
        config.environment = :prelive
        config.client_id = 'test_client_id'
        config.client_secret = 'test_client_secret'
        config.scope = 'test_scope'
      end
    end

    it 'is accessible via ZaiPayment.batch_transactions' do
      expect(ZaiPayment.batch_transactions).to be_a(described_class)
    end
  end
end
