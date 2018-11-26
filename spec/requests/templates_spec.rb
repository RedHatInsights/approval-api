# spec/requests/templates_spec.rb

RSpec.describe 'Templates API', :type => :request do
  # initialize test data
  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }

  let(:admin_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }
  let(:user_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    before { get "#{api_version}/templates", :headers => admin_encode_key }

    it 'returns templates' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    before { get "#{api_version}/templates/#{template_id}", :headers => admin_encode_key }

    context 'when the record exists' do
      it 'returns the template' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(template_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end

  # Test suite for POST /templates
  describe 'POST /templates' do
    # valid payload
    let(:valid_attributes) { { :title => 'Learn Elm', :description => '1234' } }

    context 'when the request is valid' do
      before { post "#{api_version}/templates", :params => valid_attributes, :headers => admin_encode_key }

      it 'creates a template' do
        expect(json['title']).to eq('Learn Elm')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post "#{api_version}/templates", :params => { :description => '1234' }, :headers => admin_encode_key }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Title can't be blank/)
      end
    end
  end

  # Test suite for PUT /templates/:id
  describe 'PUT /templates/:id' do
    let(:valid_attributes) { { :title => 'Shopping', :description => '1234' } }

    context 'when the record exists' do
      before { put "#{api_version}/templates/#{template_id}", :params => valid_attributes, :headers => admin_encode_key }

      it 'updates the record' do
        expect(response.body).to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end

  # Test suite for DELETE /templates/:id
  describe 'DELETE /templates/:id' do
    before { delete "#{api_version}/templates/#{template_id}", :headers => admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
