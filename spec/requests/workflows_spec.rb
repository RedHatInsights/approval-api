# spec/requests/workflows_spec.rb
require 'rails_helper'

RSpec.describe 'Workflows API' do
  # Initialize the test data
  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 20, template_id: template.id) }
  let(:id) { workflows.first.id }

  describe 'GET /templates/:template_id/workflows' do
    before { get "/templates/#{template_id}/workflows" }

    context 'when template exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all template workflows' do
        expect(json.size).to eq(20)
      end
    end

    context 'when template does not exist' do
      let(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end

  # Test suite for GET /templates/:template_id/workflows/:id
  describe 'GET /templates/:template_id/workflows/:id' do
    before { get "/templates/#{template_id}/workflows/#{id}" }

    context 'when template item exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the item' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when template item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

#  # Test suite for GET /workflows
#  describe 'GET /workflows' do
#    before { get '/workflows' }
#
#    it 'returns worlflows' do
#      expect(json).not_to be_empty
#      expect(json.size).to eq(20)
#    end
#
#    it 'returns status code 200' do
#      expect(response).to have_http_status(200)
#    end
#  end

  # Test suite for PUT /templates/:template_id/workflows
  describe 'POST /templates/:template_id/workflows' do
    let(:valid_attributes) { { name: 'Visit Narnia', done: false } }

    context 'when request attributes are valid' do
      before { post "/templates/#{template_id}/workflows", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/templates/#{template_id}/workflows", params: {} }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for PUT /templates/:template_id/workflows/:id
  describe 'PUT /templates/:template_id/workflows/:id' do
    let(:valid_attributes) { { name: 'Mozart' } }

    before { put "/templates/#{template_id}/workflows/#{id}", params: valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Workflow.find(id)
        expect(updated_item.name).to match(/Mozart/)
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for DELETE /templates/:id
  describe 'DELETE /templates/:id' do
    before { delete "/templates/#{template_id}/workflows/#{id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
