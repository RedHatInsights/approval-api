# spec/requests/stages_spec.rb

RSpec.describe 'Stages API' do
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, :template_id => template.id) }
  let!(:request) { create(:request, :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let(:request_id) { request.id }

  let!(:group_ref) { "990" }
  let!(:stages) { create_list(:stage, 5, :group_ref => group_ref, :request_id => request.id, :tenant_id => tenant.id) }
  let(:id) { stages.first.id }

  let(:api_version) { version }

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    before { get "#{api_version}/stages/#{id}", :headers => request_header }

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
      let!(:id) { 0 }

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
    before { get "#{api_version}/requests/#{request_id}/stages", :headers => request_header }

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
      let!(:request_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end
end
