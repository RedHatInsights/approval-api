RSpec.describe Api::V1x0::StagesController, :type => :request do
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

  before { allow(Group).to receive(:find) }

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    context 'when admin' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      before do
        allow(RBAC::Access).to receive(:new).with('stages', 'read').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)
        get "#{api_version}/stages/#{id}", :headers => request_header
      end

      it 'returns the stage' do
        stage = stages.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(stage.id.to_s)
        expect(json['created_at']).to eq(stage.created_at.iso8601)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:id) { 0 }
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      before do
        allow(RBAC::Access).to receive(:new).with('stages', 'read').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)
        get "#{api_version}/stages/#{id}", :headers => request_header
      end

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
    let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

    before do
      allow(RBAC::Access).to receive(:new).with('stages', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api_version}/requests/#{request_id}/stages", :headers => request_header
    end

    context 'when the record exists' do
      it 'returns the stages' do
        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(5)
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
