RSpec.describe Api::V1x0::RequestsController, :type => :request do
  include_context "approval_rbac_objects"
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:tenant) { create(:tenant) }

  let(:headers_with_admin)     { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_ADMIN) }
  let(:headers_with_approver)  { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_APPROVER) }
  let(:headers_with_requester) { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_REQUESTER) }

  let(:workflow) { create(:workflow, :name => 'Test always approve') }
  let(:workflow_id) { workflow.id }
  let(:requests) do
    Insights::API::Common::Request.with_request(default_request_hash) do
      create_list(:request, 2, :workflow_id => workflow.id, :tenant_id => tenant.id)
    end
  end
  let(:id) { requests.first.id }
  let(:requests_with_same_state) { create_list(:request, 2, :state => 'notified', :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let(:requests_with_same_decision) { create_list(:request, 2, :decision => 'approved', :workflow_id => workflow.id, :tenant_id => tenant.id) }

  let(:group1) { instance_double(Group, :name => 'group1', :uuid => "123", :has_role? => true) }
  let(:group2) { instance_double(Group, :name => 'group2', :uuid => "456") }
  let(:workflow_2) { create(:workflow, :name => 'workflow_2', :group_refs => [group1.uuid, group2.uuid], :tenant_id => tenant.id) }
  let(:user_requests) { create_list(:request, 2, :decision => 'denied', :state => 'completed', :group_ref => group1.uuid, :workflow_id => workflow_2.id, :tenant_id => tenant.id) }

  let(:roles_obj) { instance_double(Insights::API::Common::RBAC::Roles) }
  let(:workflow_find_service) { instance_double(WorkflowFindService) }

  let(:setup_requests) do
    requests
    requests_with_same_state
    requests_with_same_decision
    user_requests
  end

  let(:setup_approver_role_with_acls) do
    setup_requests
    aces = [
      AccessControlEntry.new(:permission => 'approve', :group_uuid => group1.uuid, :tenant_id => tenant.id),
      AccessControlEntry.new(:permission => 'approve', :group_uuid => group2.uuid, :tenant_id => tenant.id)
    ]

    workflow_2.update!(:access_control_entries => aces)
    allow(rs_class).to receive(:paginate).and_return([group1, group2])
    allow(roles_obj).to receive(:roles).and_return([approver_role])
  end

  let(:setup_admin_role) do
    setup_requests
    allow(rs_class).to receive(:paginate).and_return([])
    allow(roles_obj).to receive(:roles).and_return([admin_role])
  end

  let(:setup_requester_role) do
    setup_requests
    allow(rs_class).to receive(:paginate).and_return([])
    allow(roles_obj).to receive(:roles).and_return([])
  end

  let(:api_version) { version }

  before do
    allow(WorkflowFindService).to receive(:new).and_return(workflow_find_service)
    allow(Insights::API::Common::RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
  end

  describe 'GET /requests (for admin persona)' do
    context 'admin role' do
      before { setup_admin_role }

      it 'lists all requests' do
        get "#{api_version}/requests", :headers => headers_with_admin

        expect(response).to have_http_status(200)
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(8)

        # it 'sets the context'
        expect(requests.first.context.keys).to eq %w[headers original_url]
        expect(requests.first.context['headers']['x-rh-identity']).to eq encoded_user

        # it 'does not include context in the response'
        expect(json.key?("context")).to be_falsey

        # it 'can recreate the request from context' do
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
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      it 'returns status code 403' do
        get "#{api_version}/requests", :headers => headers_with_admin

        expect(response).to have_http_status(403)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'returns status code 403' do
        get "#{api_version}/requests", :headers => headers_with_admin

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /requests (for approval persona)' do
    context 'admin role' do
      before { setup_admin_role }

      it 'returns status code 403' do
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(200)
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(user_requests.count)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'returns status code 403' do
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /requests (for requesters persona)' do
    context 'admin role' do
      before { setup_admin_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET /requests for unknown persona' do
    before { setup_requester_role }

    it 'returns status code 403' do
      get "#{api_version}/requests", :headers => default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/unknown')
      expect(response).to have_http_status(403)
    end
  end

  # Test suite for GET /requests?state=
  describe 'GET /requests?state=notified' do
    context 'admin role' do
      before { setup_admin_role }

      it 'returns status code 200' do
        get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_admin

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(2)
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      it 'returns status code 200' do
        get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_approver

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'Accessible requests for approvers or requesters' do
    before do
      allow(Group).to receive(:find).and_return(group1)
    end

    let(:template) { create(:template) }
    let(:group_a) { instance_double(Group, :name => 'group_a', :uuid => "g_a") }
    let(:group_b) { instance_double(Group, :name => 'group_b', :uuid => "g_b") }
    let(:group_c) { instance_double(Group, :name => 'group_c', :uuid => "g_c") }
    let(:group_d) { instance_double(Group, :name => 'group_d', :uuid => "g_d") }
    let(:group_e) { instance_double(Group, :name => 'group_e', :uuid => "g_e") }
    let!(:workflow_a) do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        WorkflowCreateService.new(template.id).create(:name => 'workflow_a', :group_refs => [group_a.uuid, group_b.uuid])
      end
    end
    let!(:workflow_b) do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        WorkflowCreateService.new(template.id).create(:name => 'workflow_b', :group_refs => [group_b.uuid, group_d.uuid, group_e.uuid])
      end
    end
    let!(:approver_request1) { create(:request, :workflow_id => workflow_a.id, :group_ref => group_a.uuid, :tenant_id => tenant.id, :owner => 'Tom') }
    let!(:approver_request2) { create(:request, :workflow_id => workflow_b.id, :group_ref => group_b.uuid, :state => 'notified', :tenant_id => tenant.id, :owner => 'jdoe') } # default user
    let!(:actions_1) { create_list(:action, 2, :request_id => approver_request1.id, :tenant_id => tenant.id) }
    let!(:actions_2) { create_list(:action, 2, :request_id => approver_request2.id, :tenant_id => tenant.id) }

    context "approver's view" do
      context 'user in approver groups' do
        before { allow(rs_class).to receive(:paginate).and_return([group_a, group_b]) }

        it 'lists requests the approver can see' do
          expect(subject.approver_id_list("requests")).to eq([approver_request2.id])
        end

        it 'lists actions the approver can see' do
          expect(subject.approver_id_list("actions")).to eq(approver_request2.actions.pluck(:id))
        end
      end

      context 'user not in approver groups' do
        before { allow(rs_class).to receive(:paginate).and_return([group_c]) }

        it 'finds no requests the approver can see' do
          expect(subject.approver_id_list("requests")).to be_empty
        end

        it 'finds no actions the approver can see' do
          expect(subject.approver_id_list("actions")).to be_empty
        end
      end
    end

    context "requester's view" do
      it 'lists requests made by the requester' do
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          expect(subject.owner_id_list("requests")).to eq([approver_request2.id])
        end
      end

      it 'lists actions from the requests made by the requester' do
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          expect(subject.owner_id_list("actions")).to eq(approver_request2.actions.pluck(:id))
        end
      end
    end
  end

  describe 'GET /requests?decision=approved' do
    context 'admin role' do
      before { setup_admin_role }

      it 'returns status code 200' do
        get "#{api_version}/requests?filter[decision]=approved", :headers => headers_with_admin

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)

        # TODO: the following line sporadically caused build failure. Resolve it later.
        # expect(json['data'].size).to eq(2)
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      it 'returns status code 200' do
        get "#{api_version}/requests?filter[decision]=approved", :headers => headers_with_approver

        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for GET /requests/:id and /requests/:id/content
  describe 'GET /requests/:id' do
    context 'admin role' do
      before { setup_admin_role }

      context 'when the record exist' do
        it 'returns the request' do
          get "#{api_version}/requests/#{id}", :headers => default_headers

          expect(response).to have_http_status(200)
          expect(json).not_to be_empty
          expect(json['id']).to eq(requests.first.id.to_s)
        end

        it 'returns the request content' do
          get "#{api_version}/requests/#{id}/content", :headers => default_headers

          expect(response).to have_http_status(200)
          expect(json).to eq(requests.first.content)
        end
      end

      context 'when request does not exist' do
        let!(:id) { 0 }

        it 'returns status code 404' do
          get "#{api_version}/requests/#{id}", :headers => default_headers

          expect(response).to have_http_status(404)
          expect(response.body).to match(/Couldn't find Request/)
        end
      end
    end

    context 'approver role' do
      before { setup_approver_role_with_acls }

      context 'approver can approve' do
        it 'returns status code 200' do
          get "#{api_version}/requests/#{user_requests.first.id}", :headers => default_headers

          expect(response).to have_http_status(200)
        end
      end

      context 'approver cannot approve' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      context 'requester owns the request' do
        it 'returns status code 200' do
          get "#{api_version}/requests/#{id}", :headers => default_headers

          expect(response).to have_http_status(200)
        end
      end

      context 'requester does not own the requests' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  # Test suite for GET /requests/:request_id/requests
  describe 'GET /requests/:request_id/requests' do
    let!(:parent_request) { create(:request, :name => "parent", :owner => "jdoe", :number_of_children => 2, :number_of_finished_children => 0, :tenant_id => tenant.id) }
    let!(:child_request_a) { create(:request, :owner => "jdoe", :parent_id => parent_request.id, :name => "child a", :workflow_id => workflow.id, :tenant_id => tenant.id) }
    let!(:child_request_b) { create(:request, :owner => "jdoe", :parent_id => parent_request.id, :name => "child b", :workflow_id => workflow.id, :tenant_id => tenant.id) }
    let(:request_id) { parent_request.id }
    let(:group) { instance_double(Group, :name => "foo") }

    context "requester role" do
      before do
        allow(Group).to receive(:find).and_return(group)
        setup_requester_role
      end

      it 'returns status code 200' do
        get "#{api_version}/requests/#{request_id}/requests", :headers => default_headers

        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(2)
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
        'tags'        => [{:tag => '/ns1/name1=v1'}]
      }]
    end
    let(:group) { instance_double(Group, :name => 'foo', :has_role? => true) }
    let(:workflow1) { create(:workflow, :group_refs => [group1.uuid]) }
    let(:workflow2) { create(:workflow, :group_refs => [group2.uuid]) }

    before do
      allow(Thread).to receive(:new).and_yield
      allow(Group).to receive(:find).and_return(group)
      setup_requester_role
    end

    it 'returns status code 201 when no workflow is found' do
      allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([])

      with_modified_env :AUTO_APPROVAL => 'y' do
        post "#{api_version}/requests", :params => valid_attributes, :headers => default_headers
      end

      expect(response).to have_http_status(201)
    end

    it 'returns status code 201 when tags resolve to a single workflow' do
      allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1])

      post "#{api_version}/requests", :params => valid_attributes, :headers => default_headers

      expect(response).to have_http_status(201)
    end

    it 'returns status code 201 when tags resolve to multiple workflows' do
      allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1, workflow2])

      post "#{api_version}/requests", :params => valid_attributes, :headers => default_headers

      expect(response).to have_http_status(201)
      expect(Request.where(:number_of_children => 2).count).to eq 1
      expect(Request.where.not(:parent_id => nil).count).to eq 2
    end
  end
end
