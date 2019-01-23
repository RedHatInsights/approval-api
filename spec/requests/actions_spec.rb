# spec/requests/actions_spec.rb

RSpec.describe 'Actions API' do
  let!(:group) { create(:group) }
  let(:group_id) { group.id }
  let!(:stage) { create(:stage, :group_id => group.id) }
  let(:stage_id) { stage.id }

  let!(:actions) { create_list(:action, 10, :stage_id => stage.id) }
  let(:id) { actions.first.id }

  # Test suite for GET /actions
  describe 'GET /actions' do
    before { get "#{api_version}/actions" }

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
    before { get "#{api_version}/actions/#{id}" }

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
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Action/)
      end
    end
  end

  # Test suite for PATCH /groups/:group_id/actions
  describe 'POST /stages/:stage_id/actions' do
    let(:valid_attributes) { { :operation => 'notify', :processed_by => 'abcd' } }

    context 'when request attributes are valid' do
      before { post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end
end
