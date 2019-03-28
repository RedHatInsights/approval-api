# spec/requests/actions_spec.rb

RSpec.describe 'Actions API' do
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let(:request) { create(:request, :tenant_id => tenant.id) }
  let!(:group_ref) { "990" }
  let!(:stage) { create(:stage, :group_ref => group_ref, :request => request, :tenant_id => tenant.id) }
  let(:stage_id) { stage.id }

  let!(:actions) { create_list(:action, 10, :stage_id => stage.id, :tenant_id => tenant.id) }
  let(:id) { actions.first.id }

  let(:api_version) { version('v1.0') }

  # Test suite for GET /actions/:id
  describe 'GET /actions/:id' do
    before { get "#{api_version}/actions/#{id}", :headers => request_header }

    context 'when the record exists' do
      it 'returns the action' do
        action = actions.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(action.id.to_s)
        expect(json['created_at']).to eq(action.created_at.iso8601)
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
      before do
        allow(Group).to receive(:find)
        post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes, :headers => request_header
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end
end
