# spec/requests/stages_spec.rb

RSpec.describe 'Stages API' do
  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, template_id: template.id) }
  let!(:request) { create(:request, workflow_id: workflow.id) }
  let(:request_id) { request.id }

  let!(:group) { create(:group) }
  let!(:stages) { create_list(:stage, 5, group_id: group.id, request_id: request.id) }
  let(:id) { stages.first.id }

  let(:admin_encode_key) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }

  describe 'GET /stages' do
    before { get "/stages", headers: admin_encode_key }

    it 'returns stages' do
      expect(response).to have_http_status(200)
      expect(json.size).to eq(5)
    end
  end

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    before { get "/stages/#{id}", headers: admin_encode_key }

    context 'when the record exists' do
      it 'returns the stage' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Stage/)
      end
    end
  end

  # Test suite for GET /requests/:request_id/stages
  describe 'GET /requests/:request_id/stages' do
    before { get "/requests/#{request_id}/stages" }

    context 'when the record exists' do
      it 'returns the stages' do
        expect(json).not_to be_empty
        expect(json.size).to eq(5)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:request_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end

  # Test suite for POST /requests/:request_id/stages
  describe 'POST /requests/:request_id/stages' do
    let(:valid_attributes) { { state: 'skipped', decision: 'approved', group_id: group.id } }

    context 'when request attributes are valid' do
      before { post "/requests/#{request_id}/stages", params: valid_attributes, headers: admin_encode_key }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end

  # Test suite for PUT /stages/:id
  describe 'PUT /stages/:id' do
    let(:valid_attributes) { { state: 'notified' } }

    before do
      allow(ManageIQ::Messaging::Client).to receive(:open)
      put "/stages/#{id}", params: valid_attributes, headers: admin_encode_key
    end

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Stage.find(id)
        expect(updated_item.state).to eq('notified')
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Stage/)
      end
    end
  end

  # Test suite for DELETE /stages/:id
  describe 'DELETE /stages/:id' do
    before { delete "/stages/#{id}", headers: admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end

