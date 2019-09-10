RSpec.describe Api::V1x0::StagesController, :type => :request do
  include_context "rbac_objects"
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, :template_id => template.id) }
  let!(:request) { create(:request, :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let(:request_id) { request.id }

  let!(:group_ref) { "990" }
  let!(:stages) { create_list(:stage, 5, :group_ref => group_ref, :request_id => request.id, :tenant_id => tenant.id) }
  let(:id) { stages.first.id }
  let(:roles_obj) { double }
  let(:api_version) { version }

  before do
    allow(RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(Group).to receive(:find)
  end

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    context 'when the record exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/stages/#{id}", :headers => default_headers
      end

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
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/stages/#{id}", :headers => default_headers
      end

      it 'admin role returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'admin role returns a not found message' do
        expect(response.body).to match(/Couldn't find Stage/)
      end
    end

    context 'approver role can not read' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/stages/#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests/:request_id/stages
  describe 'GET /requests/:request_id/stages' do
    context 'admin role when the record exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests/#{request_id}/stages", :headers => default_headers
      end

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
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests/#{request_id}/stages", :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end

    context 'approver role can not read' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/requests/#{request_id}/stages", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
