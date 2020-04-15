RSpec.describe Api::V1x0::WorkflowsController, :type => :request do
  include_context "approval_rbac_objects"
  # Initialize the test data
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 16, :template => template, :tenant => tenant) }
  let(:id) { workflows.first.id }
  let(:add_tag_svc) { instance_double(AddRemoteTags) }
  let(:del_tag_svc) { instance_double(DeleteRemoteTags) }
  let(:get_tag_svc) { instance_double(GetRemoteTags, :tags => [tag_string]) }
  let(:tag_string) { "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=#{id}" }
  let(:tag) { {'tag' => tag_string} }

  let(:api_version) { version }

  describe 'GET /templates/:template_id/workflows' do
    context 'admin role when template exists' do
      before { admin_access }

      it 'returns status code 200' do
        get "#{api_version}/templates/#{template_id}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers

        expect(response).to have_http_status(200)
      end

      it 'returns all template workflows' do
        get "#{api_version}/templates/#{template_id}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['links']['last']).to match(/limit=5&offset=15/)
        expect(json['data'].size).to eq(5)
      end
    end

    context 'admin role when template does not exist' do
      let!(:template_id) { 0 }
      before { admin_access }

      it 'returns status code 404' do
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers

        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers

        expect(response.body).to match(/Couldn't find Template/)
      end
    end

    context 'approver role when template exists' do
      before { approver_access }

      it 'returns status code 403' do
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when template exists' do
      before { user_access }

      it 'returns status code 200' do
        get "#{api_version}/templates/#{template_id}/workflows", :headers => default_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET /workflows' do
    context 'admin role return workflows' do
      before { admin_access }

      it 'returns status code 200' do
        get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers

        expect(response).to have_http_status(200)
      end

      it 'returns all workflows' do
        get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => default_headers

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['links']['last']).to match(/limit=5&offset=15/)
        expect(json['data'].size).to eq(5)
        expect(json['data'].first['metadata']).to have_key("user_capabilities")
      end
    end

    context 'approver role return workflows' do
      before { approver_access }

      it 'returns status code 403' do
        get "#{api_version}/workflows", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role return workflows' do
      before { user_access }

      it 'returns status code 200' do
        get "#{api_version}/workflows", :headers => default_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET /workflows with filter" do
    context 'admin role return workflows' do
      before { admin_access }

      it 'returns only the filtered result' do
        get "#{api_version}/workflows?filter[id]=#{id}", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["id"]).to eq id.to_s
      end
    end

    context 'approver role return workflows' do
      before { approver_access }

      it 'returns status code 403' do
        get "#{api_version}/workflows?filter[id]=#{id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /workflows with sort_by' do
    before { admin_access }

    it "allows sorting via parameter" do
      get "#{api_version}/workflows?sort_by=name", :headers => default_headers

      expect(json["data"].map { |workflow| workflow["name"] }.sort).to eq workflows.map(&:name).sort
    end
  end

  describe 'GET /workflows/:id' do
    context 'admin role when the record exists' do
      before { admin_access }

      it 'returns the workflow' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        workflow = workflows.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(workflow.id.to_s)
        expect(json["metadata"]["user_capabilities"]).to eq(
          "create"  => true,
          "destroy" => true,
          "link"    => true,
          "show"    => true,
          "unlink"  => true,
          "update"  => true
        )
      end

      it 'returns status code 200' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'admin role when the record does not exist' do
      let!(:id) { 0 }
      before { admin_access }

      it 'returns status code 404' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end

    context 'approver role when the record exists' do
      before { approver_access }

      it 'returns status code 403' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when the record exists' do
      before { user_access }

      it 'returns status code 200' do
        get "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(200)
        expect(json["metadata"]["user_capabilities"]).to eq(
          "create"  => false,
          "destroy" => false,
          "link"    => false,
          "show"    => true,
          "unlink"  => false,
          "update"  => false
        )
      end
    end

    context 'when env BYPASS_RBAC is enabled' do
      before { user_access }

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
    let(:group_refs) { [{'name' => 'n990', 'uuid' => '990'}, {'name' => 'n991', 'uuid' => '991'}, {'name' => 'n992', 'uuid' => '992'}] }
    let(:group) { instance_double(Group, :name => 'group', :uuid => 990, :has_role? => true) }
    let(:valid_attributes) { { :name => 'Visit Narnia', :description => 'workflow_valid', :group_refs => group_refs } }

    before do
      admin_access
      allow(Group).to receive(:find).and_return(group)
    end

    context 'when admin role request attributes are valid' do
      it 'returns status code 201' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers

        expect(json['group_refs'].size).to eq(3)
        expect(response).to have_http_status(201)
      end
    end

    context 'when groups_refs contains duplicated group' do
      let(:group_refs) { [{'name' => 'n990', 'uuid' => '990'}, {'name' => 'n991', 'uuid' => '991'}, {'name' => 'n99x', 'uuid' => '990'}] }

      it 'returns status code 400' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(400)
      end
    end

    context 'when a request with missing parameter' do
      it 'returns status code 400' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes.slice(:description, :group_refs), :headers => default_headers

        expect(response.body).to match(/Validation failed:/)
        expect(response).to have_http_status(400)
      end
    end

    context 'when a request with invalid group' do
      before do
        admin_access
        allow(group).to receive(:has_role?).and_return(false)
      end

      it 'returns status code 400' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes.slice(:description, :group_refs), :headers => default_headers

        expect(response).to have_http_status(400)
        expect(response.body).to match(/does not have approver role/)
      end
    end

    context 'when approver role request attributes are valid' do
      before { approver_access }

      it 'returns status code 403' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'when regular user role request attributes are valid' do
      before { user_access }

      it 'returns status code 403' do
        post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for PATCH /workflows/:id
  describe 'PATCH /workflows/:id' do
    let(:valid_attributes) { {:name => "test", :group_refs => [{'name' => 'n1000', 'uuid' => '1000'}], :sequence => 2} }
    let(:group) { instance_double(Group, :name => 'n1000', :uuid => '1000', :has_role? => true) }

    context 'admin role when item exists' do
      before do
        admin_access
        allow(Group).to receive(:find).and_return(group)
      end

      it 'updates the item' do
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(200)
        updated_item = Workflow.find(id)
        expect(updated_item).to have_attributes(valid_attributes)
      end

      it 'returns status code 400 if sequence is not positive' do
        valid_attributes[:sequence] = -1
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(400)
      end
    end

    context 'admin role when the item does not exist' do
      let!(:id) { 0 }

      before { admin_access }

      it 'returns status code 404' do
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end

    context 'approver role when item exists' do
      before { approver_access }

      it 'returns status code 403' do
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when item exists' do
      before { user_access }

      it 'returns status code 403' do
        patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for DELETE /workflows/:id
  describe 'DELETE /workflows/:id' do
    context 'admin role when delete' do
      before { admin_access }

      it 'returns status code 204' do
        delete "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(204)
      end
    end

    context 'approver role when delete' do
      before { approver_access }

      it 'returns status code 403' do
        delete "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'regular user role when delete' do
      before { user_access }

      it 'returns status code 403' do
        delete "#{api_version}/workflows/#{id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE /workflows/:id with associated request' do
    let!(:request) { create(:request, :workflow => workflows.first) }

    before { admin_access }

    it 'returns status code 403' do
      delete "#{api_version}/workflows/#{id}", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  describe 'POST /workflows/:id/link' do
    let(:obj) { { :object_type => 'inventory', :app_name => 'topology', :object_id => '123'} }

    before do
      allow(AddRemoteTags).to receive(:new).with(obj).and_return(add_tag_svc)
      allow(add_tag_svc).to receive(:process).with([tag]).and_return(add_tag_svc)
    end

    it 'returns status code 204 for admin' do
      admin_access
      post "#{api_version}/workflows/#{id}/link", :params => obj, :headers => default_headers

      expect(response).to have_http_status(204)
      expect(TagLink.count).to eq(1)
      expect(TagLink.first.tag_name).to eq("/approval/workflows=#{id}")
      expect(TagLink.first.app_name).to eq(obj[:app_name])
      expect(TagLink.first.object_type).to eq(obj[:object_type])
    end

    it 'returns status code 403 for approver' do
      approver_access
      post "#{api_version}/workflows/#{id}/link", :params => obj, :headers => default_headers

      expect(response).to have_http_status(403)
    end

    it 'returns status code 403 for regular user' do
      user_access
      post "#{api_version}/workflows/#{id}/link", :params => obj, :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  describe 'POST /workflows/:id/unlink' do
    let(:obj) { { :object_type => 'inventory', :app_name => 'topology', :object_id => '123'} }

    before do
      allow(DeleteRemoteTags).to receive(:new).with(obj).and_return(del_tag_svc)
      allow(del_tag_svc).to receive(:process).with([tag]).and_return(del_tag_svc)
    end

    it 'returns status code 204' do
      admin_access
      post "#{api_version}/workflows/#{id}/unlink", :params => obj, :headers => default_headers

      expect(response).to have_http_status(204)
    end

    it 'returns status code 403 for approver' do
      approver_access
      post "#{api_version}/workflows/#{id}/unlink", :params => obj, :headers => default_headers

      expect(response).to have_http_status(403)
    end

    it 'returns status code 403 for regular user' do
      user_access
      post "#{api_version}/workflows/#{id}/unlink", :params => obj, :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  # TODO: resolve needs further work to query tag names
  describe 'GET /workflows?resource_object_params' do
    let(:obj_a) { { :object_type => 'ServiceInventory', :app_name => 'topology', :object_id => '123'} }
    let(:obj_b) { { :object_type => 'Portfolio', :app_name => 'catalog', :object_id => '123'} }
    let(:obj_c) { { :object_type => 'Portfolio', :object_id => '123'} }
    before do
      admin_access

      allow(AddRemoteTags).to receive(:new).with(obj_a).and_return(add_tag_svc)
      allow(add_tag_svc).to receive(:process).with([tag]).and_return(add_tag_svc)
      allow(GetRemoteTags).to receive(:new).with(obj_a).and_return(get_tag_svc)
      allow(GetRemoteTags).to receive(:new).with(obj_b).and_return(get_tag_svc)
      allow(get_tag_svc).to receive(:process).and_return(get_tag_svc)
      post "#{api_version}/workflows/#{id}/link", :params => obj_a, :headers => default_headers
    end

    it 'returns status code 200' do
      get "#{api_version}/workflows", :params => obj_a, :headers => default_headers

      expect(response).to have_http_status(200)
      expect(json["data"].first["id"].to_i).to eq(id)
    end

    it 'returns status code 200' do
      get "#{api_version}/workflows", :params => obj_b, :headers => default_headers

      expect(response).to have_http_status(200)
    end

    it 'raises an user error' do
      get "#{api_version}/workflows", :params => obj_c, :headers => default_headers

      expect(first_error_detail).to match("Exceptions::UserError: Invalid resource object params")
      expect(response).to have_http_status(400)
    end
  end

  describe 'Entitlement enforcement' do
    before { admin_access }

    let(:false_hash) do
      false_hash = default_user_hash
      false_hash["entitlements"]["ansible"]["is_entitled"] = false
      false_hash
    end

    let(:missing_hash) do
      missing_hash = default_user_hash
      missing_hash.delete("entitlements")
      missing_hash
    end

    it "fails if the ansible entitlement is false" do
      headers = { 'x-rh-identity' => encoded_user_hash(false_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :headers => headers

      expect(response).to have_http_status(:bad_request)
    end

    it "allows the request through if entitlements isn't present" do
      headers = { 'x-rh-identity' => encoded_user_hash(missing_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :headers => headers

      expect(response).to have_http_status(:ok)
    end
  end
end
