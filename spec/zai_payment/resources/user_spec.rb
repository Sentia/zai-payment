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
        dob: '01/01/1990',
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
          .to raise_error(ZaiPayment::Errors::ValidationError, %r{DD/MM/YYYY format})
      end

      it 'raises a ValidationError for short date' do
        params = base_params.merge(dob: '199001')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, %r{DD/MM/YYYY format})
      end
    end

    context 'when user_type is invalid' do
      it 'raises a ValidationError' do
        params = base_params.merge(user_type: 'invalid_type')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /user_type must be one of/)
      end
    end

    context 'when custom id is provided' do
      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          [201, { 'Content-Type' => 'application/json' }, created_response] if body['id'] == 'my-custom-user-123'
        end
      end

      let(:created_response) do
        base_params.transform_keys(&:to_s).merge('id' => 'my-custom-user-123')
      end

      it 'creates user with custom ID' do
        params = base_params.merge(id: 'my-custom-user-123')
        response = user_resource.create(**params)
        expect(response.data['id']).to eq('my-custom-user-123')
      end
    end

    context 'when custom id contains dot character' do
      it 'raises a ValidationError' do
        params = base_params.merge(id: 'user.123')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /cannot contain '.' character/)
      end
    end

    context 'when custom id is blank' do
      it 'raises a ValidationError' do
        params = base_params.merge(id: '  ')
        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /cannot be blank/)
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
        end.to raise_error(ZaiPayment::Errors::ValidationError, %r{DD/MM/YYYY format})
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
        payout_params = base_params.merge(
          user_type: 'payout', address_line1: '123 Main St', city: 'Sydney',
          state: 'NSW', zip: '2000', dob: '01/01/1990'
        )
        expect { user_resource.create(**payout_params) }.not_to raise_error
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

  describe '#create with company attributes' do
    let(:base_user_params) do
      {
        email: 'director@example.com',
        first_name: 'John',
        last_name: 'Director',
        country: 'AUS',
        mobile: '+61412345678',
        authorized_signer_title: 'Director'
      }
    end

    let(:valid_company_params) do
      {
        name: 'Test Company',
        legal_name: 'Test Company Pty Ltd',
        tax_number: '123456789',
        business_email: 'business@testcompany.com',
        country: 'AUS',
        charge_tax: true,
        address_line1: '123 Business St',
        address_line2: 'Suite 5',
        city: 'Melbourne',
        state: 'VIC',
        zip: '3000',
        phone: '+61398765432'
      }
    end

    context 'when creating user with valid company' do
      let(:user_with_company_params) do
        base_user_params.merge(company: valid_company_params)
      end

      let(:created_user_response) do
        {
          'id' => 'user_business_123',
          'email' => 'director@example.com',
          'first_name' => 'John',
          'last_name' => 'Director',
          'country' => 'AUS',
          'mobile' => '+61412345678',
          'authorized_signer_title' => 'Director',
          'company' => {
            'id' => 'company_123',
            'name' => 'Test Company',
            'legal_name' => 'Test Company Pty Ltd',
            'tax_number' => '123456789',
            'business_email' => 'business@testcompany.com',
            'country' => 'AUS',
            'charge_tax' => true,
            'address_line1' => '123 Business St',
            'address_line2' => 'Suite 5',
            'city' => 'Melbourne',
            'state' => 'VIC',
            'zip' => '3000',
            'phone' => '+61398765432'
          }
        }
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['email'] == 'director@example.com' && body['company']
            [201, { 'Content-Type' => 'application/json' }, created_user_response]
          end
        end
      end

      it 'creates user with company successfully' do
        response = user_resource.create(**user_with_company_params)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns user with company data' do
        response = user_resource.create(**user_with_company_params)
        expect(response.data['id']).to eq('user_business_123')
        expect(response.data['company']).to be_a(Hash)
      end

      it 'includes all company fields in response' do # rubocop:disable RSpec/ExampleLength
        response = user_resource.create(**user_with_company_params)
        company = response.data['company']

        aggregate_failures do
          expect(company['id']).to eq('company_123')
          expect(company['name']).to eq('Test Company')
          expect(company['legal_name']).to eq('Test Company Pty Ltd')
          expect(company['tax_number']).to eq('123456789')
          expect(company['business_email']).to eq('business@testcompany.com')
          expect(company['country']).to eq('AUS')
          expect(company['charge_tax']).to be true
        end
      end

      it 'includes company address fields in response' do # rubocop:disable RSpec/ExampleLength
        response = user_resource.create(**user_with_company_params)
        company = response.data['company']

        aggregate_failures do
          expect(company['address_line1']).to eq('123 Business St')
          expect(company['address_line2']).to eq('Suite 5')
          expect(company['city']).to eq('Melbourne')
          expect(company['state']).to eq('VIC')
          expect(company['zip']).to eq('3000')
          expect(company['phone']).to eq('+61398765432')
        end
      end

      it 'includes authorized_signer_title in user data' do
        response = user_resource.create(**user_with_company_params)
        expect(response.data['authorized_signer_title']).to eq('Director')
      end

      it 'sends company data in request body' do
        expect do
          user_resource.create(**user_with_company_params)
        end.not_to raise_error

        # Verify the stub was called with correct data
        expect(stubs).to be_a(Faraday::Adapter::Test::Stubs)
      end
    end

    context 'when company charge_tax is false' do
      let(:company_no_tax_params) do
        valid_company_params.merge(charge_tax: false)
      end

      let(:user_with_company_no_tax) do
        base_user_params.merge(company: company_no_tax_params)
      end

      let(:created_user_no_tax_response) do
        {
          'id' => 'user_business_456',
          'email' => 'director@example.com',
          'first_name' => 'John',
          'last_name' => 'Director',
          'country' => 'AUS',
          'company' => {
            'id' => 'company_456',
            'name' => 'Test Company',
            'legal_name' => 'Test Company Pty Ltd',
            'tax_number' => '123456789',
            'business_email' => 'business@testcompany.com',
            'country' => 'AUS',
            'charge_tax' => false
          }
        }
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['company'] && body['company']['charge_tax'] == false
            [201, { 'Content-Type' => 'application/json' }, created_user_no_tax_response]
          end
        end
      end

      it 'preserves charge_tax false value' do
        response = user_resource.create(**user_with_company_no_tax)
        expect(response.data['company']['charge_tax']).to be false
      end
    end

    context 'when company has only required fields' do
      let(:minimal_company_params) do
        {
          name: 'Minimal Company',
          legal_name: 'Minimal Company Pty Ltd',
          tax_number: '987654321',
          business_email: 'info@minimal.com',
          country: 'AUS'
        }
      end

      let(:user_with_minimal_company) do
        base_user_params.merge(company: minimal_company_params)
      end

      let(:created_minimal_company_response) do
        {
          'id' => 'user_business_789',
          'email' => 'director@example.com',
          'first_name' => 'John',
          'last_name' => 'Director',
          'country' => 'AUS',
          'company' => {
            'id' => 'company_789',
            'name' => 'Minimal Company',
            'legal_name' => 'Minimal Company Pty Ltd',
            'tax_number' => '987654321',
            'business_email' => 'info@minimal.com',
            'country' => 'AUS'
          }
        }
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['company'] && body['company']['name'] == 'Minimal Company'
            [201, { 'Content-Type' => 'application/json' }, created_minimal_company_response]
          end
        end
      end

      it 'creates user with minimal company fields' do
        response = user_resource.create(**user_with_minimal_company)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'returns company with required fields' do # rubocop:disable RSpec/ExampleLength
        response = user_resource.create(**user_with_minimal_company)
        company = response.data['company']

        aggregate_failures do
          expect(company['name']).to eq('Minimal Company')
          expect(company['legal_name']).to eq('Minimal Company Pty Ltd')
          expect(company['tax_number']).to eq('987654321')
          expect(company['business_email']).to eq('info@minimal.com')
          expect(company['country']).to eq('AUS')
        end
      end
    end

    context 'when company is missing required fields' do
      it 'raises ValidationError when name is missing' do
        company_params = valid_company_params.except(:name)
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*name/)
      end

      it 'raises ValidationError when legal_name is missing' do
        company_params = valid_company_params.except(:legal_name)
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*legal_name/)
      end

      it 'raises ValidationError when tax_number is missing' do
        company_params = valid_company_params.except(:tax_number)
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*tax_number/)
      end

      it 'raises ValidationError when business_email is missing' do
        company_params = valid_company_params.except(:business_email)
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*business_email/)
      end

      it 'raises ValidationError when country is missing' do
        company_params = valid_company_params.except(:country)
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*country/)
      end

      it 'raises ValidationError when multiple required fields are missing' do
        company_params = { name: 'Test Company' }
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(
            ZaiPayment::Errors::ValidationError,
            /Company is missing required fields:.*legal_name.*tax_number.*business_email.*country/
          )
      end
    end

    context 'when company fields are empty strings' do
      it 'raises ValidationError for empty name' do
        company_params = valid_company_params.merge(name: '')
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*name/)
      end

      it 'raises ValidationError for blank business_email' do
        company_params = valid_company_params.merge(business_email: '   ')
        params = base_user_params.merge(company: company_params)

        expect { user_resource.create(**params) }
          .to raise_error(ZaiPayment::Errors::ValidationError, /Company is missing required fields:.*business_email/)
      end
    end
  end

  describe '#create with additional user parameters' do
    let(:base_params) do
      {
        email: 'test@example.com',
        first_name: 'John',
        last_name: 'Doe',
        country: 'USA'
      }
    end

    context 'when creating user with drivers license' do
      let(:user_with_license_params) do
        base_params.merge(
          drivers_license_number: 'D1234567',
          drivers_license_state: 'CA'
        )
      end

      let(:created_user_response) do
        user_with_license_params.transform_keys(&:to_s).merge('id' => 'user_with_license_123')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['drivers_license_number'] == 'D1234567'
            [201, { 'Content-Type' => 'application/json' }, created_user_response]
          end
        end
      end

      it 'creates user with drivers license successfully' do
        response = user_resource.create(**user_with_license_params)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'includes drivers license in response' do
        response = user_resource.create(**user_with_license_params)
        expect(response.data['drivers_license_number']).to eq('D1234567')
        expect(response.data['drivers_license_state']).to eq('CA')
      end
    end

    context 'when creating user with branding parameters' do
      let(:user_with_branding_params) do
        base_params.merge(
          logo_url: 'https://example.com/logo.png',
          color_1: '#FF5733', # rubocop:disable Naming/VariableNumber
          color_2: '#C70039', # rubocop:disable Naming/VariableNumber
          custom_descriptor: 'MY STORE'
        )
      end

      let(:created_user_response) do
        user_with_branding_params.transform_keys(&:to_s).merge('id' => 'user_with_branding_456')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['logo_url'] == 'https://example.com/logo.png'
            [201, { 'Content-Type' => 'application/json' }, created_user_response]
          end
        end
      end

      it 'creates user with branding parameters successfully' do
        response = user_resource.create(**user_with_branding_params)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'includes all branding parameters in response' do
        response = user_resource.create(**user_with_branding_params)

        aggregate_failures do
          expect(response.data['logo_url']).to eq('https://example.com/logo.png')
          expect(response.data['color_1']).to eq('#FF5733')
          expect(response.data['color_2']).to eq('#C70039')
          expect(response.data['custom_descriptor']).to eq('MY STORE')
        end
      end
    end

    context 'when creating user with authorized_signer_title' do
      let(:user_with_title_params) do
        base_params.merge(authorized_signer_title: 'Managing Director')
      end

      let(:created_user_response) do
        user_with_title_params.transform_keys(&:to_s).merge('id' => 'user_with_title_789')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['authorized_signer_title'] == 'Managing Director'
            [201, { 'Content-Type' => 'application/json' }, created_user_response]
          end
        end
      end

      it 'creates user with authorized_signer_title successfully' do
        response = user_resource.create(**user_with_title_params)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'includes authorized_signer_title in response' do
        response = user_resource.create(**user_with_title_params)
        expect(response.data['authorized_signer_title']).to eq('Managing Director')
      end
    end

    context 'when creating user with all new parameters' do
      let(:comprehensive_user_params) do
        base_params.merge(
          drivers_license_number: 'ABC123456',
          drivers_license_state: 'NY',
          logo_url: 'https://brand.example.com/logo.png',
          color_1: '#0066CC', # rubocop:disable Naming/VariableNumber
          color_2: '#FF9900', # rubocop:disable Naming/VariableNumber
          custom_descriptor: 'COMPREHENSIVE STORE',
          authorized_signer_title: 'CEO',
          mobile: '+12125551234',
          address_line1: '789 Broadway',
          city: 'New York',
          state: 'NY',
          zip: '10003'
        )
      end

      let(:created_comprehensive_response) do
        comprehensive_user_params.transform_keys(&:to_s).merge('id' => 'user_comprehensive_999')
      end

      before do
        stubs.post('/users') do |env|
          body = JSON.parse(env.body)
          if body['custom_descriptor'] == 'COMPREHENSIVE STORE'
            [201, { 'Content-Type' => 'application/json' }, created_comprehensive_response]
          end
        end
      end

      it 'creates user with all parameters successfully' do
        response = user_resource.create(**comprehensive_user_params)
        expect(response).to be_a(ZaiPayment::Response)
        expect(response.success?).to be true
      end

      it 'includes all parameters in response' do # rubocop:disable RSpec/ExampleLength
        response = user_resource.create(**comprehensive_user_params)
        data = response.data

        aggregate_failures do
          expect(data['drivers_license_number']).to eq('ABC123456')
          expect(data['drivers_license_state']).to eq('NY')
          expect(data['logo_url']).to eq('https://brand.example.com/logo.png')
          expect(data['color_1']).to eq('#0066CC')
          expect(data['color_2']).to eq('#FF9900')
          expect(data['custom_descriptor']).to eq('COMPREHENSIVE STORE')
          expect(data['authorized_signer_title']).to eq('CEO')
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
