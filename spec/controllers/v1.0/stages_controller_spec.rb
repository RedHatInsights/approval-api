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

  before do
    allow(Group).to receive(:find)
    allow(RBAC::Access).to receive(:new).with('stages', 'read').and_return(access_obj)
    allow(access_obj).to receive(:process).and_return(access_obj)
  end

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    context 'when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }
      before { get "#{api_version}/stages/#{id}", :headers => request_header }

      it 'admin role returns the stage' do
        stage = stages.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(stage.id.to_s)
        expect(json['created_at']).to eq(stage.created_at.iso8601)
      end

      it 'admin role returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:id) { 0 }
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }
      before { get "#{api_version}/stages/#{id}", :headers => request_header }

      it 'admin role returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'admin role returns a not found message' do
        expect(response.body).to match(/Couldn't find Stage/)
      end
    end

    context 'approver role can not approve' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => false, :approver? => true, :owner? => false) }
      before do
        allow(access_obj).to receive(:not_owned?).and_return(true)
        allow(access_obj).to receive(:not_approvable?).and_return(true)
        get "#{api_version}/stages/#{id}", :headers => request_header
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'approver role can approve' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => false, :approver? => true, :owner? => false) }
      before do
        allow(access_obj).to receive(:not_owned?).and_return(true)
        allow(access_obj).to receive(:not_approvable?).and_return(false)
        get "#{api_version}/stages/#{id}", :headers => request_header
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for GET /requests/:request_id/stages
  describe 'GET /requests/:request_id/stages' do
    before do
      allow(access_obj).to receive(:approver_id_list).and_return([])
      allow(access_obj).to receive(:owner_id_list).and_return([])

      get "#{api_version}/requests/#{request_id}/stages", :headers => request_header
    end

    context 'admin role when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      it 'returns the stages' do
        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(5)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'admin role when the record does not exist' do
      let!(:request_id) { 0 }
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end
end
