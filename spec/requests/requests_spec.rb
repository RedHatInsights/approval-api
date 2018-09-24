# spec/requests/requests_spec.rb
require 'rails_helper'

RSpec.describe 'Requests API' do
  # Initialize the test data
  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, template_id: template.id) }
  let(:workflow_id) { workflow.id }
  let!(:requests) { create_list(:request, 20, workflow_id: workflow.id, status: 'PENDING', state: 'QUEUED') }
  let(:id) { requests.first.id }

  # Test suite for GET /workflows/:workflow_id/requests
  describe 'GET /workflows/:workflow_id/requests' do
    before { get "/workflows/#{workflow_id}/requests" }

    context 'when workflow exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all workflow requests' do
        expect(json.size).to eq(20)
      end
    end

    context 'when workflow does not exist' do
      let(:workflow_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for GET /workflows/:workflow_id/requests/:id
  describe 'GET /workflows/:workflow_id/requests/:id' do
    before { get "/workflows/#{workflow_id}/requests/#{id}" }

    context 'when workflow exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the item' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when workflow does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end

  # Test suite for PUT /workflows/:workflow_id/requests
  describe 'POST /workflows/:workflow_id/requests' do
    let(:valid_attributes) { { uuid: '1234', name: 'Visit Narnia', content: 'cpu', status: 'PENDING', state: 'QUEUED' } }

    context 'when request attributes are valid' do
      before { post "/workflows/#{workflow_id}/requests", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/workflows/#{workflow_id}/requests", params: {uuid: '1234', name: 'Visit Narnia', content: 'cpu', status: 'PENDING'} }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: State can't be blank/)
      end
    end
  end

  # Test suite for PUT /workflows/:workflow_id/requests/:id
  describe 'PUT /workflows/:workflow_id/requests/:id' do
    let(:valid_attributes) { { name: 'Mozart' } }

    before { put "/workflows/#{workflow_id}/requests/#{id}", params: valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Request.find(id)
        expect(updated_item.name).to match(/Mozart/)
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end
 
  # Test suite for DELETE /workflows/:workflow_id/requests/:id
  describe 'DELETE /workflows/:workflow_id/requests/:id' do
    before { delete "/workflows/#{workflow_id}/requests/#{id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
