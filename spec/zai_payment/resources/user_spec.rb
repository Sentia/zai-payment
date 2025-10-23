# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe ZaiPayment::Resources::User do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:user_resource) { described_class.new(client: test_client) }

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

  describe '#list' do
    context 'when successful' do
      before do
        stubs.get('/users') do |env|
          [200, { 'Content-Type' => 'application/json' }, user_list_data] if env.params['limit'] == '10'
        end
      end

      let(:user_list_data) do
        {
          'users' => [
            {
              'id' => 'user_1',
              'email' => 'buyer@example.com',
              'first_name' => 'John',
              'last_name' => 'Doe',
              'country' => 'USA'
            },
            {
              'id' => 'user_2',
              'email' => 'seller@example.com',
              'first_name' => 'Jane',
              'last_name' => 'Smith',
              'country' => 'AUS'
            }
          ],
          'meta' => {
            'total' => 2,
            'limit' => 10,
            'offset' => 0
          }
        }
      end

      it 'returns the correct response type' do
        response = user_resource.list
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the user data' do
        response = user_resource.list
        expect(response.data).to eq(user_list_data['users'])
      end

      it 'returns the metadata' do
        response = user_resource.list
        expect(response.meta).to eq(user_list_data['meta'])
      end
    end

    context 'with custom pagination' do
      before do
        stubs.get('/users') do |env|
          [200, { 'Content-Type' => 'application/json' }, user_list_data] if env.params['limit'] == '20'
        end
      end

      let(:user_list_data) do
        {
          'users' => [],
          'meta' => { 'total' => 0, 'limit' => 20, 'offset' => 10 }
        }
      end

      it 'accepts custom limit and offset' do
        response = user_resource.list(limit: 20, offset: 10)
        expect(response.success?).to be true
      end
    end

    context 'when unauthorized' do
      before do
        stubs.get('/users') do
          [401, { 'Content-Type' => 'application/json' }, { 'error' => 'Unauthorized' }]
        end
      end

      it 'raises an UnauthorizedError' do
        expect { user_resource.list }.to raise_error(ZaiPayment::Errors::UnauthorizedError)
      end
    end
  end

  describe '#show' do
    context 'when user exists' do
      before do
        stubs.get('/users/user_123') do
          [200, { 'Content-Type' => 'application/json' }, user_detail]
        end
      end

      let(:user_detail) do
        {
          'id' => 'user_123',
          'email' => 'john.doe@example.com',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'country' => 'USA',
          'city' => 'New York',
          'state' => 'NY'
        }
      end

      it 'returns the correct response type' do
        response = user_resource.show('user_123')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the user details' do
        response = user_resource.show('user_123')
        expect(response.data['id']).to eq('user_123')
        expect(response.data['email']).to eq('john.doe@example.com')
      end
    end

    context 'when user does not exist' do
      before do
        stubs.get('/users/user_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'User not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect { user_resource.show('user_123') }.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end

    context 'when user_id is blank' do
      it 'raises a ValidationError for empty string' do
        expect { user_resource.show('') }.to raise_error(ZaiPayment::Errors::ValidationError, /user_id/)
      end

      it 'raises a ValidationError for nil' do
        expect { user_resource.show(nil) }.to raise_error(ZaiPayment::Errors::ValidationError, /user_id/)
      end
    end
  end

  describe '#create' do
    let(:base_params) do
      {
        email: 'test@example.com',
        first_name: 'John',
        last_name: 'Doe',
        country: 'USA'
      }
    end

    let(:payin_user_params) do
      base_params.merge(
        email: 'buyer@example.com',
        mobile: '+1234567890',
        address_line1: '123 Main St',
        city: 'New York',
        state: 'NY',
        zip: '10001'
      )
    end

    let(:payout_user_params) do
      base_params.merge(
        email: 'seller@example.com',
        dob: '19900101',
        address_line1: '456 Market St',
        city: 'Sydney',
        state: 'NSW',
        zip: '2000',
        mobile: '+61412345678'
      )
    end

    context 'when creating a payin user' do
      let(:created_payin_response) do
        payin_user_params.transform_keys(&:to_s).merge('id' => 'user_payin_new')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['email'] == payin_user_params[:email]
            [201, { 'Content-Type' => 'application/json' }, created_payin_response]
          end
        end
      end

      it 'returns the correct response type' do
        response = user_resource.create(**payin_user_params)
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'returns the created user with correct data' do
        response = user_resource.create(**payin_user_params)
        expect(response.data['id']).to eq('user_payin_new')
        expect(response.data['email']).to eq(payin_user_params[:email])
        expect(response.data['first_name']).to eq(payin_user_params[:first_name])
      end
    end

    context 'when creating a payout user' do
      let(:created_payout_response) do
        payout_user_params.transform_keys(&:to_s).merge('id' => 'user_payout_new')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['email'] == payout_user_params[:email]
            [201, { 'Content-Type' => 'application/json' }, created_payout_response]
          end
        end
      end

      it 'returns the correct response type' do
        response = user_resource.create(**payout_user_params)
        expect(response).to be_a(ZaiPayment::Response)
      end

      it 'returns the created user with correct data' do
        response = user_resource.create(**payout_user_params)
        expect(response.data['id']).to eq('user_payout_new')
        expect(response.data['email']).to eq(payout_user_params[:email])
        expect(response.data['dob']).to eq(payout_user_params[:dob])
      end
    end

    context 'when required fields are missing' do
      it 'raises a ValidationError for missing email' do
        params = {
          first_name: 'John',
          last_name: 'Doe',
          country: 'USA'
        }
        expect { user_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*email/
        )
      end

      it 'raises a ValidationError for missing first_name' do
        params = {
          email: 'test@example.com',
          last_name: 'Doe',
          country: 'USA'
        }
        expect { user_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*first_name/
        )
      end

      it 'raises a ValidationError for missing last_name' do
        params = {
          email: 'test@example.com',
          first_name: 'John',
          country: 'USA'
        }
        expect { user_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*last_name/
        )
      end

      it 'raises a ValidationError for missing country' do
        params = {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
        expect { user_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*country/
        )
      end

      it 'raises a ValidationError for multiple missing fields' do
        params = {
          email: 'test@example.com'
        }
        expect { user_resource.create(**params) }.to raise_error(
          ZaiPayment::Errors::ValidationError, /Missing required fields:.*first_name.*last_name.*country/
        )
      end
    end

    context 'when email is invalid' do
      it 'raises a ValidationError' do
        params = {
          email: 'invalid-email',
          first_name: 'John',
          last_name: 'Doe',
          country: 'USA'
        }
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /valid email address/)
      end

      it 'raises a ValidationError for email without @' do
        params = {
          email: 'invalidemail.com',
          first_name: 'John',
          last_name: 'Doe',
          country: 'USA'
        }
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /valid email address/)
      end
    end

    context 'when country is invalid' do
      it 'raises a ValidationError for non-ISO code' do
        params = {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
          country: 'US'
        }
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /ISO 3166-1 alpha-3 code/)
      end

      it 'raises a ValidationError for invalid country code' do
        params = {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
          country: 'USAA'
        }
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /ISO 3166-1 alpha-3 code/)
      end
    end

    context 'when dob is invalid' do
      it 'raises a ValidationError for incorrect format' do
        params = base_params.merge(dob: '1990-01-01')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /YYYYMMDD format/)
      end

      it 'raises a ValidationError for short date' do
        params = base_params.merge(dob: '199001')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /YYYYMMDD format/)
      end
    end

    context 'when user_type is invalid' do
      it 'raises a ValidationError' do
        params = base_params.merge(user_type: 'invalid_type')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /user_type must be one of/)
      end
    end

    context 'when API returns validation error' do
      before do
        stubs.post('/users') do
          [422, { 'Content-Type' => 'application/json' }, { 'errors' => ['Email is already taken'] }]
        end
      end

      it 'raises a ValidationError' do
        params = {
          email: 'duplicate@example.com',
          first_name: 'John',
          last_name: 'Doe',
          country: 'USA'
        }
        expect { user_resource.create(**params) }.to raise_error(ZaiPayment::Errors::ValidationError)
      end
    end
  end

  describe '#update' do
    context 'when successful' do
      before do
        stubs.patch('/users/user_123') do |env|
          body = JSON.parse(env.body)
          [200, { 'Content-Type' => 'application/json' }, updated_response] if body['mobile'] == '+9876543210'
        end
      end

      let(:updated_response) do
        {
          'id' => 'user_123',
          'email' => 'john.doe@example.com',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'mobile' => '+9876543210',
          'address_line1' => '789 New St',
          'country' => 'USA'
        }
      end

      it 'returns the correct response type' do
        response = user_resource.update('user_123', mobile: '+9876543210', address_line1: '789 New St')
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns the updated user data' do
        response = user_resource.update('user_123', mobile: '+9876543210', address_line1: '789 New St')
        expect(response.data['mobile']).to eq('+9876543210')
        expect(response.data['address_line1']).to eq('789 New St')
      end
    end

    context 'when user_id is blank' do
      it 'raises a ValidationError' do
        expect do
          user_resource.update('', mobile: '+1234567890')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /user_id/)
      end
    end

    context 'when no update parameters provided' do
      it 'raises a ValidationError' do
        expect do
          user_resource.update('user_123')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /At least one attribute/)
      end
    end

    context 'when email is invalid' do
      it 'raises a ValidationError' do
        expect do
          user_resource.update('user_123', email: 'invalid-email')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /valid email address/)
      end
    end

    context 'when dob is invalid' do
      it 'raises a ValidationError' do
        expect do
          user_resource.update('user_123', dob: '1990-01-01')
        end.to raise_error(ZaiPayment::Errors::ValidationError, /YYYYMMDD format/)
      end
    end

    context 'when user does not exist' do
      before do
        stubs.patch('/users/user_123') do
          [404, { 'Content-Type' => 'application/json' }, { 'error' => 'User not found' }]
        end
      end

      it 'raises a NotFoundError' do
        expect do
          user_resource.update('user_123', mobile: '+1234567890')
        end.to raise_error(ZaiPayment::Errors::NotFoundError)
      end
    end
  end

  describe 'user type validation' do
    context 'with valid user types' do
      let(:base_params) do
        {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
          country: 'USA'
        }
      end

      before do
        stubs.post('/users') do
          [201, { 'Content-Type' => 'application/json' }, { 'id' => 'user_new' }]
        end
      end

      it 'accepts payin user type' do
        params = base_params.merge(user_type: 'payin')
        expect { user_resource.create(**params) }.not_to raise_error
      end

      it 'accepts payout user type' do
        params = base_params.merge(user_type: 'payout')
        expect { user_resource.create(**params) }.not_to raise_error
      end

      it 'accepts uppercase user type' do
        params = base_params.merge(user_type: 'PAYIN')
        expect { user_resource.create(**params) }.not_to raise_error
      end
    end
  end

  describe 'integration with ZaiPayment module' do
    it 'is accessible through ZaiPayment.users' do
      expect(ZaiPayment.users).to be_a(described_class)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
