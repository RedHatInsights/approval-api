# spec/requests/requests_spec.rb

RSpec.describe 'Requests API' do
  # Initialize the test data
  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, template_id: template.id) }
  let(:workflow_id) { workflow.id }
  let!(:requests) { create_list(:request, 2, workflow_id: workflow.id) }
  let(:id) { requests.first.id }
  let!(:requests_with_same_state) { create_list(:request, 2, state: 'notified', workflow_id: workflow.id) }
  let!(:requests_with_same_decision) { create_list(:request, 2, decision: 'approved', workflow_id: workflow.id) }


  let(:user_encode_key) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }
  let(:admin_encode_key) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }

  # Test suite for GET /workflows/:workflow_id/requests
  describe 'GET /workflows/:workflow_id/requests' do
    before { get "/workflows/#{workflow_id}/requests", headers: admin_encode_key }

    context 'when workflow exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all workflow requests' do
        expect(json.size).to eq(6)
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

  # Test suite for GET /requests
  describe 'GET /requests' do
    before { get '/requests', headers: admin_encode_key }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(6)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests?state=
  describe 'GET /requests?state=notified' do
    before { get '/requests?state=notified', headers: admin_encode_key }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(2)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests?decision=
  describe 'GET /requests?decision=approved' do
    before { get '/requests?decision=approved', headers: admin_encode_key }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(2)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests/:id
  describe 'GET /requests/:id' do
    before { get "/requests/#{id}" }

    context 'when the record exist' do
      it 'returns the request' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when request does not exist' do
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
    let(:item) { { 'disk' => '100GB' } }
    let(:valid_attributes) { { requester: '1234', name: 'Visit Narnia', content: JSON.generate(item), decision: 'unknown', state: 'pending' } }

    context 'when request attributes are valid' do
      before { post "/workflows/#{workflow_id}/requests", params: valid_attributes, headers: admin_encode_key }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/workflows/#{workflow_id}/requests", params: {requester: '1234', name: 'Visit Narnia', content: JSON.generate(item), decision: 'bad', state: 'pending'}, headers: admin_encode_key }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Decision is not included in the list/)
      end
    end
  end

  # Test suite for PUT /requests/:id
  describe 'PUT /requests/:id' do
    let(:valid_attributes) { { name: 'Mozart' } }

    before { put "/requests/#{id}", params: valid_attributes, headers: admin_encode_key }

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

    context 'when status has invalid value' do
      before { put "/requests/#{id}", params: {decision: 'bad', state: 'pending'}, headers: admin_encode_key }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end
    end

    context 'when state has invalid value' do
      before { put "/requests/#{id}", params: {state: 'bad_state'}, headers: admin_encode_key }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end
    end
  end

  # Test suite for DELETE /requests/:id
  describe 'DELETE /requests/:id' do
    before { delete "/requests/#{id}", headers: admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
