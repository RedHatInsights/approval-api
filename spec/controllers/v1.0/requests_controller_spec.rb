RSpec.describe Api::V1x0::RequestsController, :type => :request do
  include_context "approval_rbac_objects"
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:owner) { default_user_hash['identity']['user']['username'] }
  let(:tenant) { create(:tenant) }

  let(:headers_with_admin)     { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
  let(:headers_with_approver)  { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
  let(:headers_with_requester) { default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }

  let(:group1) { instance_double(Group, :name => 'group1', :uuid => "123", :has_role? => true) }
  let(:group2) { instance_double(Group, :name => 'group2', :uuid => "456") }
  let(:group3) { instance_double(Group, :name => 'group3', :uuid => "789") }

  let(:workflow1) { create(:workflow, :name => 'wf1', :group_refs => [{'name' => group3.name, 'uuid' => group3.uuid}], :tenant => tenant) }
  let(:workflow2) { create(:workflow, :name => 'wf2', :group_refs => [{'name' => group1.name, 'uuid' => group1.uuid}, {'name' => group2.name, 'uuid' => group2.uuid}], :tenant => tenant) }

  let(:notified_request) do
    Insights::API::Common::Request.with_request(default_request_hash) { create(:request, :state => 'notified', :tenant => tenant) }
  end
  let(:notified_request_sub1) { create(:request, :state => 'pending', :parent => notified_request, :owner => owner, :workflow => workflow1, :group_ref => group3.uuid, :tenant => tenant)}
  let(:notified_request_sub2) { create(:request, :state => 'notified', :parent => notified_request, :owner => owner, :workflow => workflow2, :group_ref => group2.uuid, :tenant => tenant)}

  let(:denied_request) { create(:request, :state => 'completed', :decision => 'denied', :reason => 'bad', :tenant => tenant) }
  let(:denied_request_sub1) { create(:request, :state => 'completed', :decision => 'approved', :parent => denied_request, :workflow => workflow2, :group_ref => group1.uuid, :tenant => tenant)}
  let(:denied_request_sub2) { create(:request, :state => 'completed', :decision => 'denied', :reason => 'bad', :parent => denied_request, :workflow => workflow2, :group_ref => group2.uuid, :tenant => tenant)}

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
    approver_access
  end

  let(:setup_admin_role) do
    setup_requests
    admin_access
  end

  let(:setup_requester_role) do
    setup_requests
    user_access
  end

  let(:api_version) { version }

  before do
    allow(WorkflowFindService).to receive(:new).and_return(workflow_find_service)
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi, any_args).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  describe 'GET /requests' do
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
        expect(json['data'].first['metadata']).to have_key("user_capabilities")

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

      it 'returns status code 200' do
        allow(user).to receive(:group_uuids).and_return([group2.uuid])
        get "#{api_version}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(200)
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(2)
        expect(json['data'].first).to include('id' => denied_request_sub2.id.to_s)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'returns status code 200' do
        get "#{api_version}/requests", :headers => headers_with_requester

        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(1)
      end
    end
  end

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
        allow(user).to receive(:group_uuids).and_return([group2.uuid])
        get "#{api_version}/requests?filter[state]=notified", :headers => headers_with_approver

        expect(json['data'].size).to eq(1)
        expect(response).to have_http_status(200)
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
      before do
        setup_approver_role
        allow(user).to receive(:group_uuids).and_return([group2.uuid])
      end

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
          get "#{api_version}/requests/#{notified_request.id}", :headers => headers_with_admin

          expect(response).to have_http_status(200)
          expect(json).not_to be_empty
          expect(json['id']).to eq(notified_request.id.to_s)
          expect(json['metadata']['user_capabilities']).to eq(
            "approve" => true,
            "cancel"  => true,
            "create"  => true,
            "deny"    => true,
            "memo"    => true,
            "show"    => true
          )
        end

        it 'returns the request content' do
          get "#{api_version}/requests/#{notified_request.id}/content", :headers => headers_with_admin

          expect(response).to have_http_status(200)
          expect(json).to eq(notified_request.content)
        end
      end

      context 'when request does not exist' do
        let!(:id) { 0 }

        it 'returns status code 404' do
          get "#{api_version}/requests/#{id}", :headers => headers_with_admin

          expect(response).to have_http_status(404)
          expect(response.body).to match(/Couldn't find Request/)
        end
      end
    end

    context 'approver role' do
      before do
        setup_approver_role
        allow(user).to receive(:group_uuids).and_return([group2.uuid])
      end

      context 'approver can approve' do
        it 'returns status code 200 for completed request' do
          get "#{api_version}/requests/#{denied_request_sub2.id}", :headers => headers_with_approver

          expect(response).to have_http_status(200)
          expect(json['metadata']['user_capabilities']).to eq(
            "approve" => false,
            "cancel"  => false,
            "create"  => false,
            "deny"    => false,
            "memo"    => true,
            "show"    => true
          )
        end

        it 'returns status code 200 for approvable request' do
          get "#{api_version}/requests/#{notified_request_sub2.id}", :headers => headers_with_approver

          expect(response).to have_http_status(200)
          expect(json['metadata']['user_capabilities']).to eq(
            "approve" => true,
            "cancel"  => false,
            "create"  => false,
            "deny"    => true,
            "memo"    => true,
            "show"    => true
          )
        end
      end

      context 'approver cannot approve' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{denied_request.id}", :headers => headers_with_approver

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      context 'requester owns the request' do
        it 'returns status code 200' do
          get "#{api_version}/requests/#{notified_request.id}", :headers => headers_with_requester

          expect(response).to have_http_status(200)
          expect(json['metadata']['user_capabilities']).to eq(
            "approve" => false,
            "cancel"  => true,
            "create"  => true,
            "deny"    => false,
            "memo"    => true,
            "show"    => true
          )
        end
      end

      context 'requester does not own the requests' do
        it 'returns status code 403' do
          get "#{api_version}/requests/#{denied_request.id}", :headers => headers_with_requester

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  # Test suite for GET /requests/:request_id/requests
  describe 'GET /requests/:request_id/requests' do
    context 'admin role' do
      let(:params) { { :request_id => "#{denied_request.id}" } }
      before { setup_admin_role }

      it 'returns status code 200' do
        get "#{api_version}/requests/#{denied_request.id}/requests", :headers => headers_with_admin

        expect(response).to have_http_status(200)
        expect(json['data'].size).to eq(2)
      end
    end

    context 'approver role' do
      let(:params) { { :request_id => "#{denied_request.id}" } }
      before do
        setup_approver_role
        allow(user).to receive(:group_uuids).and_return([group2.uuid])
      end

      it 'returns status code 403' do
        get "#{api_version}/requests/#{denied_request.id}/requests", :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end

    context "requester role" do
      let(:params) { { :request_id => "#{notified_request.id}" } }
      before { setup_requester_role }

      it 'returns status code 200' do
        get "#{api_version}/requests/#{notified_request.id}/requests", :headers => headers_with_requester

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
          post "#{api_version}/requests", :params => valid_attributes, :headers => headers_with_requester
        end

        expect(response).to have_http_status(201)
      end

      it 'returns status code 201 when tags resolve to a single workflow' do
        allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1])

        post "#{api_version}/requests", :params => valid_attributes, :headers => headers_with_requester

        expect(response).to have_http_status(201)
      end

      it 'returns status code 201 when tags resolve to multiple workflows' do
        allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1, workflow2])

        post "#{api_version}/requests", :params => valid_attributes, :headers => headers_with_requester

        expect(response).to have_http_status(201)
        request = Request.find(json['id'])
        expect(request).to have_attributes(:number_of_children => 2, :parent_id => nil)
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      it 'returns status code 403' do
        allow(workflow_find_service).to receive(:find_by_tag_resources).and_return([workflow1])

        post "#{api_version}/requests", :params => valid_attributes, :headers => headers_with_approver

        expect(response).to have_http_status(403)
      end
    end
  end
end
