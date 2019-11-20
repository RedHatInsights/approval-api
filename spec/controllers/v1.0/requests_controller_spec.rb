RSpec.describe Api::V1x0::RequestsController, :type => :request do
  include_context "approval_rbac_objects"
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:tenant) { create(:tenant) }

  let(:headers_with_admin)     { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_ADMIN) }
  let(:headers_with_approver)  { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_APPROVER) }
  let(:headers_with_requester) { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_REQUESTER) }

  let!(:workflow) { create(:workflow, :name => 'Test always approve') }
  let(:workflow_id) { workflow.id }
  let!(:requests) do
    Insights::API::Common::Request.with_request(:headers => default_headers, :original_url => "localhost/approval") do
      create_list(:request, 2, :workflow_id => workflow.id, :tenant_id => tenant.id)
    end
  end
  let(:id) { requests.first.id }
  let!(:requests_with_same_state) { create_list(:request, 2, :state => 'notified', :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let!(:requests_with_same_decision) { create_list(:request, 2, :decision => 'approved', :workflow_id => workflow.id, :tenant_id => tenant.id) }

  let(:username_1) { "joe@acme.com" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "456") }
  let!(:workflow_2) { create(:workflow, :name => 'workflow_2', :group_refs => [group1.uuid, group2.uuid]) }
  let!(:user_requests) { create_list(:request, 2, :decision => 'denied', :workflow_id => workflow_2.id, :tenant_id => tenant.id) }
  let!(:stages1) { create(:stage, :group_ref => group1.uuid, :state => 'notified', :request_id => user_requests.first.id, :tenant_id => tenant.id) }
  let!(:stages2) { create(:stage, :group_ref => group2.uuid, :state => 'pending', :request_id => user_requests.first.id, :tenant_id => tenant.id) }
  let!(:stages3) { create(:stage, :group_ref => group1.uuid, :state => 'notified', :request_id => user_requests.last.id, :tenant_id => tenant.id) }
  let!(:stages4) { create(:stage, :group_ref => group2.uuid, :state => 'pending', :request_id => user_requests.last.id, :tenant_id => tenant.id) }

  let(:filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflow_2.id) }
  let(:resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter) }
  let(:access) { instance_double(RBACApiClient::Access, :permission => "approval:workflows:approve", :resource_definitions => [resource_def]) }
  let(:full_approver_acls) { approver_acls << access }
  let(:roles_obj) { double }

  let(:group1_role) { "approval-group-#{group1.uuid}" }
  let(:api_version) { version }

  before do
    allow(Insights::API::Common::RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  # Test suite for GET /workflows/:workflow_id/requests
  xdescribe 'GET /workflows/:workflow_id/requests' do
    context 'when admins' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => headers_with_admin
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all workflow requests' do
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(6)
      end
    end

    context 'when approver' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
      end

      it 'returns status code 403' do
        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => headers_with_admin
        expect(response).to have_http_status(403)
      end
    end

    context 'when owner' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])

        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => headers_with_admin
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests for admin persona
  xdescribe 'GET /requests (for admin persona)' do
    context 'as admin role' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])

        get "#{api_version}/requests", :headers => headers_with_admin
      end

      it 'returns requests' do
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(8)
      end

      it 'sets the context' do
        expect(requests.first.context.keys).to eq %w[headers original_url]
        expect(requests.first.context['headers']['x-rh-identity']).to eq encoded_user
      end

      it 'does not include context in the response' do
        expect(json.key?("context")).to be_falsey
      end

      it 'can recreate the request from context' do
        req = nil
        Insights::API::Common::Request.with_request(:headers => default_headers, :original_url => "approval.com/approval") do
          req = create(:request)
        end

        new_request = req.context.transform_keys(&:to_sym)
        Insights::API::Common::Request.with_request(new_request) do
          expect(Insights::API::Common::Request.current.user.username).to eq "jdoe"
          expect(Insights::API::Common::Request.current.user.email).to eq "jdoe@acme.com"
        end
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'as approver role' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])
        get "#{api_version}/requests", :headers => headers_with_admin
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'as regular user role' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        get "#{api_version}/requests", :headers => headers_with_admin
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests for approval persona
  xdescribe 'GET /requests (for approval persona)' do
    context 'as admin role' do
      it 'returns status code 403' do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end

    context 'as approver role' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => full_approver_acls) }

      it 'returns status code 200' do
        allow(rs_class).to receive(:paginate).and_return(full_approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, group1_role])
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(200)

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(user_requests.count)
      end
    end

    context 'as regular user' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }

      it 'returns status code 403' do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests for regular users
  xdescribe 'GET /requests (for requesters)' do
    context 'as admin role' do
      it 'returns requests' do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])

        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end

    context 'as approver role' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => approver_acls) }

      it 'returns status code 200' do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])

        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end

    context 'as regular user' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }

      it 'returns status code 200' do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])

        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end
  end

  xdescribe 'GET /requests for unknown persona' do
    let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }

    it 'returns status code 403' do
      allow(rs_class).to receive(:paginate).and_return([])
      allow(access_obj).to receive(:process).and_return(access_obj)
      allow(roles_obj).to receive(:roles).and_return([])

      get "#{api_version}/requests", :headers => default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/unknown')
      expect(response).to have_http_status(403)
    end
  end

  # Test suite for GET /requests?state=
  xdescribe 'GET /requests?state=notified' do
    it 'admin role returns requests' do
      allow(rs_class).to receive(:paginate).and_return([])
      allow(roles_obj).to receive(:roles).and_return([admin_role])
      get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_admin

      expect(json['links']).not_to be_empty
      expect(json['links']['first']).to match(/offset=0/)
      expect(json['data'].size).to eq(2)
      expect(response).to have_http_status(200)
    end

    context 'as approver role' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => full_approver_acls) }

      it 'approver role returns status code 200' do
        allow(rs_class).to receive(:paginate).and_return(full_approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, group1_role])
        get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_approver

        expect(response).to have_http_status(200)
      end
    end
  end

  xdescribe 'Accessible requests for Approver persona' do
    let(:ctrl) { described_class.new }
    let(:group_a) { double(:name => 'group_a', :uuid => "g_a") }
    let(:group_b) { double(:name => 'group_b', :uuid => "g_b") }
    let(:group_c) { double(:name => 'group_c', :uuid => "g_c") }
    let(:group_d) { double(:name => 'group_d', :uuid => "g_d") }
    let(:group_e) { double(:name => 'group_e', :uuid => "g_e") }
    let!(:workflow_a) { create(:workflow, :name => 'workflow_a', :group_refs => [group_a.uuid, group_b.uuid, group_c.uuid]) }
    let!(:workflow_b) { create(:workflow, :name => 'workflow_b', :group_refs => [group_b.uuid, group_d.uuid, group_e.uuid]) }
    let!(:approver_request1) { create(:request, :workflow_id => workflow_a.id, :tenant_id => tenant.id) }
    let!(:approver_request2) { create(:request, :workflow_id => workflow_b.id, :tenant_id => tenant.id) }
    let!(:stage_a) { create(:stage, :group_ref => group_a.uuid, :state => 'notified', :request_id => approver_request1.id, :tenant_id => tenant.id) }
    let!(:stage_b) { create(:stage, :group_ref => group_b.uuid, :request_id => approver_request1.id, :tenant_id => tenant.id) }
    let!(:stage_c) { create(:stage, :group_ref => group_c.uuid, :request_id => approver_request1.id, :tenant_id => tenant.id) }
    let!(:stage_d) { create(:stage, :state => 'finished', :group_ref => group_b.uuid, :request_id => approver_request2.id, :tenant_id => tenant.id) }
    let!(:stage_e) { create(:stage, :state => 'finished', :group_ref => group_d.uuid, :request_id => approver_request2.id, :tenant_id => tenant.id) }
    let!(:stage_f) { create(:stage, :group_ref => group_e.uuid, :request_id => approver_request2.id, :tenant_id => tenant.id) }
    let!(:role_a) { "approval-group-#{group_a.uuid}" }
    let!(:role_b) { "approval-group-#{group_b.uuid}" }
    let!(:role_d) { "approval-group-#{group_d.uuid}" }

    context "when filter stages with groups" do
      it '#approver_stage_ids for standalone group' do
        allow(roles_obj).to receive(:roles).and_return([approver_role, role_a])
        allow(ctrl).to receive(:workflow_ids).and_return([workflow_a.id, workflow_b.id])

        expect(ctrl.approver_stage_ids).to eq([stage_a.id])
      end

      it '#approver_stage_ids for shared group' do
        allow(roles_obj).to receive(:roles).and_return([approver_role, role_b])
        allow(ctrl).to receive(:workflow_ids).and_return([workflow_a.id, workflow_b.id])

        # stage_b is still in the list waiting for processing
        expect(ctrl.approver_stage_ids).to eq([stage_d.id])
      end
    end

    context "when return ids based on resource type" do
      it '#approver_id_list for requests' do
        allow(roles_obj).to receive(:roles).and_return([approver_role, role_b])
        allow(ctrl).to receive(:workflow_ids).and_return([workflow_a.id, workflow_b.id])

        expect(ctrl.approver_id_list("requests")).to eq([approver_request2.id])
      end

      it '#approver_id_list for next stages' do
        allow(roles_obj).to receive(:roles).and_return([approver_role, role_b])
        allow(ctrl).to receive(:workflow_ids).and_return([workflow_a.id, workflow_b.id])

        expect(ctrl.approver_id_list("stages")).to eq([stage_d.id])
      end

      it '#approver_id_list for previous stages' do
        allow(roles_obj).to receive(:roles).and_return([approver_role, role_d])
        allow(ctrl).to receive(:workflow_ids).and_return([workflow_a.id, workflow_b.id])

        expect(ctrl.approver_id_list("stages")).to eq([stage_e.id])
      end
    end
  end

  # Test suite for GET /requests?decision=
  xdescribe 'GET /requests?decision=approved' do
    context 'as admin role' do
      it 'admin role returns requests' do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests?filter[decision]=approved", :headers => headers_with_admin

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)

        # TODO: the following line sporadically caused build failure. Resolve it later.
        # expect(json['data'].size).to eq(2)
        expect(response).to have_http_status(200)
      end

      context 'as approver' do
        let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => full_approver_acls) }
        it 'approver role returns status code 200' do
          allow(rs_class).to receive(:paginate).and_return(full_approver_acls)
          allow(access_obj).to receive(:process).and_return(access_obj)
          allow(roles_obj).to receive(:roles).and_return([approver_role, group1_role])
          get "#{api_version}/requests?filter[decision]=approved", :headers => headers_with_approver

          expect(response).to have_http_status(200)
        end
      end
    end
  end

  # Test suite for GET /requests/:id
  xdescribe 'GET /requests/:id' do
    context 'admin role when the record exist' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests/#{id}", :headers => default_headers
      end

      it 'returns the request' do
        request = requests.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(request.id.to_s)
        expect(json['created_at']).to eq(request.created_at.iso8601)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'admin role when request does not exist' do
      let!(:id) { 0 }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        get "#{api_version}/requests/#{id}", :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end

    context 'approver can approve' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => full_approver_acls) }
      let(:approver_group_role) { "approval-group-#{group1.uuid}" }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, approver_group_role])

        get "#{api_version}/requests/#{user_requests.first.id}", :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver cannot approve' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => full_approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])

        get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner own the requests' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])

        get "#{api_version}/requests/#{id}", :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'owner does not own the requests' do
      let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])

        get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for POST /requests
  describe 'POST /requests' do
    let(:item) { { 'disk' => '100GB' } }
    let(:valid_attributes) { { :tag_resources => tag_resources, :name => 'Visit Narnia', :content => item, :description => 'desc' } }
    let(:tag_resources) do
      [{
        'app_name'    => 'app1',
        'object_type' => 'otype1',
        'tags'        => [{'namespace' => 'ns1', 'name' => 'name1', 'value' => 'v1'}]
      }]
    end

    context 'any role' do
      it 'returns status code 201' do
        with_modified_env :AUTO_APPROVAL => 'y' do
          allow(rs_class).to receive(:paginate).and_return([])
          allow(roles_obj).to receive(:roles).and_return([admin_role])
          post "#{api_version}/requests", :params => valid_attributes, :headers => default_headers
        end

        expect(response).to have_http_status(201)
      end
    end
  end
end
