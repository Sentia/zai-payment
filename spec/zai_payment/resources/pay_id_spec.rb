# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Resources::PayId do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:pay_id_resource) { described_class.new(client: test_client) }

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

  describe '#create' do
    let(:pay_id_data) do
      {
        'pay_ids' => {
          'id' => '46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
          'pay_id' => 'jsmith@mydomain.com',
          'type' => 'EMAIL',
          'status' => 'pending_activation',
          'created_at' => '2020-04-27T20:28:22.378Z',
          'updated_at' => '2020-04-27T20:28:22.378Z',
          'details' => {
            'pay_id_name' => 'J Smith',
            'owner_legal_name' => 'Mr John Smith'
          },
          'links' => {
            'self' => '/pay_ids/46deb476-c1a6-41eb-8eb7-26a695bbe5bc',
            'virtual_accounts' => '/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc'
          }
        }
      }
    end

    let(:valid_params) do
      {
        pay_id: 'jsmith@mydomain.com',
        type: 'EMAIL',
        details: {
          pay_id_name: 'J Smith',
          owner_legal_name: 'Mr John Smith'
        }
      }
    end

    context 'when successful' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [202, { 'Content-Type' => 'application/json' }, pay_id_data]
        end
      end

      it 'returns the correct response type and creates PayID' do
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
        expect(response.data['id']).to eq('46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end

      it 'includes pay_id and type in response' do
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params)

        expect(response.data['pay_id']).to eq('jsmith@mydomain.com')
        expect(response.data['type']).to eq('EMAIL')
      end

      it 'includes details in response' do
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params)

        expect(response.data['details']['pay_id_name']).to eq('J Smith')
        expect(response.data['details']['owner_legal_name']).to eq('Mr John Smith')
      end

      it 'includes status and timestamps' do
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params)

        expect(response.data['status']).to eq('pending_activation')
        expect(response.data['created_at']).to eq('2020-04-27T20:28:22.378Z')
        expect(response.data['updated_at']).to eq('2020-04-27T20:28:22.378Z')
      end

      it 'includes links in response' do
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params)

        expect(response.data['links']).to be_a(Hash)
        expect(response.data['links']['self']).to eq('/pay_ids/46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
        expect(response.data['links']['virtual_accounts'])
          .to eq('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc')
      end
    end

    context 'with lowercase type' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [202, { 'Content-Type' => 'application/json' }, pay_id_data]
        end
      end

      it 'converts type to uppercase' do
        params = valid_params.merge(type: 'email')
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with minimal details' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [202, { 'Content-Type' => 'application/json' }, pay_id_data]
        end
      end

      it 'accepts empty details hash' do
        params = valid_params.merge(details: {})
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with maximum length pay_id' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [202, { 'Content-Type' => 'application/json' }, pay_id_data]
        end
      end

      it 'accepts pay_id with 256 characters' do
        max_length_pay_id = 'a' * 256
        params = valid_params.merge(pay_id: max_length_pay_id)
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'with maximum length detail fields' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [202, { 'Content-Type' => 'application/json' }, pay_id_data]
        end
      end

      it 'accepts detail fields with 140 characters' do
        long_details = {
          pay_id_name: 'A' * 140,
          owner_legal_name: 'B' * 140
        }
        params = valid_params.merge(details: long_details)
        response = pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)

        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end
    end

    context 'when virtual_account_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { pay_id_resource.create('', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { pay_id_resource.create(nil, **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end

      it 'raises a ValidationError for whitespace only' do
        expect { pay_id_resource.create('   ', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /virtual_account_id/)
      end
    end

    context 'when pay_id validation fails' do
      it 'raises error for blank pay_id' do
        params = valid_params.merge(pay_id: '')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /pay_id is required/)
      end

      it 'raises error for nil pay_id' do
        params = valid_params.merge(pay_id: nil)
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /pay_id is required/)
      end

      it 'raises error for whitespace only pay_id' do
        params = valid_params.merge(pay_id: '   ')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /pay_id is required/)
      end

      it 'raises error for pay_id longer than 256 characters' do
        long_pay_id = 'a' * 257
        params = valid_params.merge(pay_id: long_pay_id)
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /pay_id must be 256 characters or less/)
      end
    end

    context 'when type validation fails' do
      it 'raises error for blank type' do
        params = valid_params.merge(type: '')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /type is required/)
      end

      it 'raises error for nil type' do
        params = valid_params.merge(type: nil)
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /type is required/)
      end

      it 'raises error for whitespace only type' do
        params = valid_params.merge(type: '   ')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /type is required/)
      end

      it 'raises error for invalid type' do
        params = valid_params.merge(type: 'PHONE')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /type must be one of: EMAIL/)
      end

      it 'includes the invalid type in error message' do
        params = valid_params.merge(type: 'INVALID')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /got 'INVALID'/)
      end
    end

    context 'when details validation fails' do
      it 'raises error for nil details' do
        params = valid_params.merge(details: nil)
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /details is required and must be a hash/)
      end

      it 'raises error for non-hash details' do
        params = valid_params.merge(details: 'not a hash')
        expect do
          pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params)
        end.to raise_error(ZaiPayment::Errors::ValidationError, /details is required and must be a hash/)
      end

      it 'raises error for pay_id_name longer than 140 characters' do
        long_details = {
          pay_id_name: 'A' * 141,
          owner_legal_name: 'John Smith'
        }
        params = valid_params.merge(details: long_details)

        expect { pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /pay_id_name must be between 1 and 140 characters/)
      end

      it 'raises error for owner_legal_name longer than 140 characters' do
        long_details = {
          pay_id_name: 'J Smith',
          owner_legal_name: 'B' * 141
        }
        params = valid_params.merge(details: long_details)

        expect { pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /owner_legal_name must be between 1 and 140 characters/)
      end
    end

    context 'when virtual account does not exist' do
      before do
        stubs.post('/virtual_accounts/invalid_id/pay_ids') do
          [404, { 'Content-Type' => 'application/json' }, { 'errors' => 'Not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { pay_id_resource.create('invalid_id', **valid_params) }
          .to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when API returns bad request' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [400, { 'Content-Type' => 'application/json' }, { 'errors' => 'Bad request' }]
        end
      end

      it 'raises a BadRequestError' do
        expect { pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params) }
          .to raise_error(ZaiPayment::Errors::BadRequestError)
      end
    end

    context 'when API returns unauthorized' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [401, { 'Content-Type' => 'application/json' }, { 'errors' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params) }
          .to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end

    context 'when API returns forbidden' do
      before do
        stubs.post('/virtual_accounts/46deb476-c1a6-41eb-8eb7-26a695bbe5bc/pay_ids') do
          [403, { 'Content-Type' => 'application/json' }, { 'errors' => 'Forbidden' }]
        end
      end

      it 'raises a ForbiddenError' do
        expect { pay_id_resource.create('46deb476-c1a6-41eb-8eb7-26a695bbe5bc', **valid_params) }
          .to raise_error(ZaiPayment::Errors::ForbiddenError)
      end
    end
  end
end
