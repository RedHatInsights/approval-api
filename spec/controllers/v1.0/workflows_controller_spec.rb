RSpec.describe Api::V1x0::WorkflowsController, :type => :request do
  include_context "rbac_objects"
  # Initialize the test data
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 16, :template_id => template.id) }
  let(:id) { workflows.first.id }
  let(:roles_obj) { double }

  let(:api_version) { version }

  before do
    allow(RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(roles_obj).to receive(:roles)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  describe 'GET /templates/:template_id/workflows' do
    context 'admin role when template exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/templates/#{template_id}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all template workflows' do
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['links']['last']).to match(/limit=5&offset=15/)
        expect(json['data'].size).to eq(5)
      end
    end

    context 'admin role when template does not exist' do
      let!(:template_id) { 0 }

      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end

    context 'approver role when template exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when template exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /workflows' do
    context 'admin role return workflows' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all workflows' do
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['links']['last']).to match(/limit=5&offset=15/)
        expect(json['data'].size).to eq(5)
      end
    end

    context 'approver role return workflows' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/workflows", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role return workflows' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        get "#{api_version}/workflows", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "GET /workflows with filter" do
    context 'admin role return workflows' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/workflows?filter[id]=#{id}", :headers => default_headers
      end

      it 'returns only the filtered result' do
        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["id"]).to eq id.to_s
      end
    end

    context 'approver role return workflows' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/workflows?filter[id]=#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /workflows/:id' do
    context 'admin role when the record exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns the workflow' do
        workflow = workflows.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(workflow.id.to_s)
        expect(json['created_at']).to eq(workflow.created_at.iso8601)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'admin role when the record does not exist' do
      let!(:id) { 0 }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end

    context 'approver role when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        get "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when env BYPASS_RBAC is enabled' do
      it 'returns status code 200' do
        with_modified_env :BYPASS_RBAC => 'y' do
          get "#{api_version}/workflows/#{id}", :headers => default_headers

          expect(response).to have_http_status(200)
        end
      end
    end
  end

  # Test suite for POST /templates/:template_id/workflows
  describe 'POST /templates/:template_id/workflows' do
    let(:group_refs) { %w[990 991 992] }

    let(:valid_attributes) { { :name => 'Visit Narnia', :description => 'workflow_valid', :group_refs => group_refs } }
    let(:aps) { instance_double(AccessProcessService) }

    before do
      allow(AccessProcessService).to receive(:new).and_return(aps)
      allow(aps).to receive(:add_resource_to_groups)
    end

    context 'when admin role request attributes are valid' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers, :as => :json
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when a request with missing parameter' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes.slice(:description, :group_refs), :headers => default_headers, :as => :json
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed:/)
      end
    end

    context 'when approver role request attributes are valid' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers, :as => :json
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when regular user role request attributes are valid' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers, :as => :json
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for PATCH /workflows/:id
  describe 'PATCH /workflows/:id' do
    let(:valid_attributes) { { :group_refs => %w[1000] } }
    let(:aps) { instance_double(AccessProcessService) }

    before do
      allow(AccessProcessService).to receive(:new).and_return(aps)
      allow(aps).to receive(:add_resource_to_groups)
      allow(aps).to receive(:remove_resource_from_groups)
    end

    context 'admin role when item exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the item' do
        updated_item = Workflow.find(id)
        expect(updated_item.group_refs).to match(["1000"])
      end
    end

    context 'admin role when the item does not exist' do
      let!(:id) { 0 }

      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end

    context 'approver role when item exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when item exists' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for DELETE /workflows/:id
  describe 'DELETE /workflows/:id' do
    context 'admin role when delete' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        delete "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end

    context 'approver role when delete' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        delete "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when delete' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        delete "#{api_version}/workflows/#{id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE /workflows/:id with associated request' do
    let!(:request) { create(:request, :workflow => workflows.first) }

    before do
      allow(rs_class).to receive(:paginate).and_return([])
      allow(roles_obj).to receive(:roles).and_return([admin_role])
      delete "#{api_version}/workflows/#{id}", :headers => default_headers
    end

    it 'returns status code 403' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'DELETE /workflows/:id of default workflow' do
    before do
      allow(rs_class).to receive(:paginate).and_return([])
      allow(roles_obj).to receive(:roles).and_return([admin_role])

      Workflow.seed
      delete "#{api_version}/workflows/#{Workflow.default_workflow.id}", :headers => default_headers
    end

    after { Workflow.instance_variable_set(:@default_workflow, nil) }

    it 'returns status code 403' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'Entitlement enforcement' do
    let(:false_hash) do
      false_hash = default_user_hash
      false_hash["entitlements"]["hybrid_cloud"]["is_entitled"] = false
      false_hash
    end
    let(:missing_hash) do
      missing_hash = default_user_hash
      missing_hash.delete("entitlements")
      missing_hash
    end

    before do
      allow(rs_class).to receive(:paginate).and_return([])
      allow(roles_obj).to receive(:roles).and_return([admin_role])
    end

    it "fails if the hybrid_cloud entitlement is false" do
      headers = { 'x-rh-identity' => encoded_user_hash(false_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :headers => headers

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the request through if entitlements isn't present" do
      headers = { 'x-rh-identity' => encoded_user_hash(missing_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :headers => headers

      expect(response).to have_http_status(:ok)
    end
  end
end
