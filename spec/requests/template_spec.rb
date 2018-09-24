# spec/requests/templates_spec.rb
require 'rails_helper'

RSpec.describe 'Templates API', type: :request do
  # initialize test data 
  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    before { get '/templates' }

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
    before { get "/templates/#{template_id}" }

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
      let(:template_id) { 100 }

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
    let(:valid_attributes) { { title: 'Learn Elm', description: '1234', created_by: '1' } }

    context 'when the request is valid' do
      before { post '/templates', params: valid_attributes }

      it 'creates a template' do
        expect(json['title']).to eq('Learn Elm')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/templates', params: { title: 'Foobar', description: '1234' } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Created by can't be blank/)
      end
    end
  end

  # Test suite for PUT /templates/:id
  describe 'PUT /templates/:id' do
    let(:valid_attributes) { { title: 'Shopping', description: '1234', created_by: '1' } }

    context 'when the record exists' do
      before { put "/templates/#{template_id}", params: valid_attributes }

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
    before { delete "/templates/#{template_id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
