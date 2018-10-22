# spec/requests/actions_spec.rb

RSpec.describe 'Actions API' do
  let!(:group) { create(:group) }
  let(:group_id) { group.id }
  let!(:stage) { create(:stage, group_id: group.id) }
  let(:stage_id) { stage.id }

  let!(:actions) { create_list(:action, 10, stage_id: stage.id) }
  let(:id) { actions.first.id }

  let(:user_encode_key) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }
  let(:admin_encode_key) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }

  # Test suite for GET /actions
  describe 'GET /actions' do
    before { get "/actions", headers: admin_encode_key }

    it 'returns actions' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /actions/:id
  describe 'GET /actions/:id' do
    before { get "/actions/#{id}", headers: admin_encode_key }

    context 'when the record exists' do
      it 'returns the action' do
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
        expect(response.body).to match(/Couldn't find Action/)
      end
    end
  end

  # Test suite for PUT /groups/:group_id/actions
  describe 'POST /stages/:stage_id/actions' do
    let(:valid_attributes) { { decision: 'unknown', processed_by: 'abcd' } }

    context 'when request attributes are valid' do
      before { post "/stages/#{stage_id}/actions", params: valid_attributes, headers: admin_encode_key }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end

  # Test suite for PUT /actions/:id
  describe 'PUT /actions/:id' do
    let(:valid_attributes) { { processed_by: 'abcd', decision: 'denied' } }

    before { put "/actions/#{id}", params: valid_attributes, headers: admin_encode_key }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Action.find(id)
        expect(updated_item.processed_by).to eq('abcd')
        expect(updated_item.decision).to eq('denied')
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Action/)
      end
    end
  end

  # Test suite for DELETE /actions/:id
  describe 'DELETE /actions/:id' do
    before { delete "/actions/#{id}", headers: admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
