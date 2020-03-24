RSpec.describe Api::V1x0::RequestsController, :type => :request do
  include_context "approval_rbac_objects"
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:owner) { default_user_hash['identity']['user']['username'] }
  let(:tenant) { create(:tenant) }

  let(:headers_with_admin)     { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_ADMIN) }
  let(:headers_with_approver)  { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_APPROVER) }
  let(:headers_with_requester) { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => described_class::PERSONA_REQUESTER) }

  let(:group1) { instance_double(Group, :name => 'group1', :uuid => "123", :has_role? => true) }
  let(:group2) { instance_double(Group, :name => 'group2', :uuid => "456") }
  let(:group3) { instance_double(Group, :name => 'group3', :uuid => "789") }

  let(:workflow1) { create(:workflow, :name => 'wf1', :group_refs => [group3.uuid], :tenant => tenant) }
  let(:workflow2) { create(:workflow, :name => 'wf2', :group_refs => [group1.uuid, group2.uuid], :tenant => tenant) }

  let(:notified_request) do
    Insights::API::Common::Request.with_request(default_request_hash) { create(:request, :state => 'notified', :tenant => tenant) }
  end
  let(:notified_request_sub1) { create(:request, :state => 'notified', :parent => notified_request, :owner => owner, :workflow => workflow1, :group_ref => group3.uuid, :tenant => tenant)}
  let(:notified_request_sub2) { create(:request, :state => 'pending', :parent => notified_request, :owner => owner, :workflow => workflow2, :group_ref => group2.uuid, :tenant => tenant)}

  let(:denied_request) { create(:request, :state => 'completed', :decision => 'denied', :reason => 'bad', :tenant => tenant) }
  let(:denied_request_sub1) { create(:request, :state => 'completed', :decision => 'approved', :parent => denied_request, :workflow => workflow2, :group_ref => group1.uuid, :tenant => tenant)}
  let(:denied_request_sub2) { create(:request, :state => 'completed', :decision => 'denied', :reason => 'bad', :parent => denied_request, :workflow => workflow2, :group_ref => group2.uuid, :tenant => tenant)}

  let(:roles_obj) { instance_double(Insights::API::Common::RBAC::Roles) }
  let(:workflow_find_service) { instance_double(WorkflowFindService) }

  let(:setup_requests) do
    notified_request
    notified_request_sub1
    notified_request_sub2
    denied_request
    denied_request_sub1
    denied_request_sub2
  end

  let(:setup_approver_role) do
    setup_requests
    allow(rs_class).to receive(:paginate).and_return([group2])
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
        expect(json['data'].size).to eq(2)
        expect(json['data'].first).to include('id' => denied_request.id.to_s)
        expect(json['data'].second).to include('id' => notified_request.id.to_s)

        # it 'sets the context'
        expect(notified_request.context.keys).to eq %w[headers original_url]
        expect(notified_request.context['headers']['x-rh-identity']).to eq encoded_user

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
      before { setup_approver_role }

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
      before { setup_approver_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(200)
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(1)
        expect(json['data'].first).to include('id' => denied_request_sub2.id.to_s)
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
        expect(json['data'].size).to eq(1)
        expect(json['data'].first).to include('id' => notified_request.id.to_s)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester
        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)

        get "#{api_version}/requests", :headers => default_headers
        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)
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
        expect(json['data'].size).to eq(1)
        expect(json['data'].first).to include('id' => notified_request.id.to_s)
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 200' do
        get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_approver

        expect(json['data'].size).to eq(0)
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
    let!(:approver_request1) { create(:request, :workflow => workflow_a, :group_ref => group_a.uuid, :tenant => tenant, :owner => 'Tom') }
    let!(:approver_request2) { create(:request, :workflow => workflow_b, :group_ref => group_b.uuid, :state => 'notified', :tenant => tenant, :owner => 'jdoe') } # default user
    let!(:actions_1) { create_list(:action, 2, :request => approver_request1, :tenant => tenant) }
    let!(:actions_2) { create_list(:action, 2, :request => approver_request2, :tenant => tenant) }

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
        get "#{api_version}/requests?filter[decision]=denied", :headers => headers_with_admin

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)

        expect(json['data'].size).to eq(1)
        expect(json['data'].first).to include('id' => denied_request.id.to_s)
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 200 with decision = approved' do
        get "#{api_version}/requests?filter[decision]=approved", :headers => headers_with_approver

        expect(json['data'].size).to be_zero
        expect(response).to have_http_status(200)
      end

      it 'returns status code 200 with decision = denied' do
        get "#{api_version}/requests?filter[decision]=denied", :headers => headers_with_approver

        expect(json['data'].size).to eq(1)
        expect(json['data'].first).to include('id' => denied_request_sub2.id.to_s)
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
          get "#{api_version}/requests/#{notified_request.id}", :headers => default_headers

          expect(response).to have_http_status(200)
          expect(json).not_to be_empty
          expect(json['id']).to eq(notified_request.id.to_s)
        end

        it 'returns the request content' do
          get "#{api_version}/requests/#{notified_request.id}/content", :headers => default_headers

          expect(response).to have_http_status(200)
          expect(json).to eq(notified_request.content)
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
      before { setup_approver_role }

      context 'approver can approve' do
        it 'returns status code 200' do
          get "#{api_version}/requests/#{denied_request_sub2.id}", :headers => default_headers

          expect(response).to have_http_status(200)
        end
      end

      context 'approver cannot approve' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{denied_request.id}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      context 'requester owns the request' do
        it 'returns status code 200' do
          get "#{api_version}/requests/#{notified_request.id}", :headers => default_headers

          expect(response).to have_http_status(200)
        end
      end

      context 'requester does not own the requests' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{denied_request.id}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  # Test suite for GET /requests/:request_id/requests
  describe 'GET /requests/:request_id/requests' do
    context 'admin role' do
      before { setup_admin_role }

      it 'returns status code 200' do
        get "#{api_version}/requests/#{denied_request.id}/requests", :headers => headers_with_admin

        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(2)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 403' do
        get "#{api_version}/requests/#{denied_request.id}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end

    context "requester role" do
      before { setup_requester_role }

      it 'returns status code 200' do
        get "#{api_version}/requests/#{notified_request.id}/requests", :headers => default_headers

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
    end

    context 'requester role' do
      before { setup_requester_role }

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
        request = Request.find(json['id'])
        expect(request).to have_attributes(:number_of_children => 2, :parent_id => nil)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 201' do
        allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1])

        post "#{api_version}/requests", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(201)
      end
    end
  end
end
