RSpec.describe Api::V1x0::RequestsController, :type => :request do
  include_context "rbac_objects"
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let!(:workflow) { create(:workflow, :name => 'Test always approve') }
  let(:workflow_id) { workflow.id }
  let!(:requests) do
    ManageIQ::API::Common::Request.with_request(:headers => default_headers, :original_url => "localhost/approval") do
      create_list(:request, 2, :workflow_id => workflow.id, :tenant_id => tenant.id)
    end
  end
  let(:id) { requests.first.id }
  let!(:requests_with_same_state) { create_list(:request, 2, :state => 'notified', :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let!(:requests_with_same_decision) { create_list(:request, 2, :decision => 'approved', :workflow_id => workflow.id, :tenant_id => tenant.id) }

  let(:username_1) { "joe@acme.com" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let!(:workflow_2) { create(:workflow, :name => 'workflow_2', :group_refs => [group1.uuid]) }
  let!(:user_requests) { create_list(:request, 2, :decision => 'denied', :workflow_id => workflow_2.id, :tenant_id => tenant.id) }
  let!(:list_service) { RequestListByApproverService.new(username_1) }

  let(:filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflow_2.id) }
  let(:resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter) }
  let(:access) { instance_double(RBACApiClient::Access, :permission => "approval:workflows:approve", :resource_definitions => [resource_def]) }
  let(:full_approver_acls) { approver_acls << access }

  let(:api_version) { version }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  # Test suite for GET /workflows/:workflow_id/requests
  describe 'GET /workflows/:workflow_id/requests' do
    context 'when admins' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => default_headers
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
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
      end

      it 'returns status code 403' do
        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => default_headers
        expect(response).to have_http_status(403)
      end
    end

    context 'when owner' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)

        get "#{api_version}/workflows/#{workflow_id}/requests", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests
  describe 'GET /requests' do
    context 'as admin role' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)

        get "#{api_version}/requests", :headers => default_headers
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
        ManageIQ::API::Common::Request.with_request(:headers => default_headers, :original_url => "approval.com/approval") do
          req = create(:request)
        end

        new_request = req.context.transform_keys(&:to_sym)
        ManageIQ::API::Common::Request.with_request(new_request) do
          expect(ManageIQ::API::Common::Request.current.user.username).to eq "jdoe"
          expect(ManageIQ::API::Common::Request.current.user.email).to eq "jdoe@acme.com"
        end
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'as approver role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        get "#{api_version}/requests", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'as owner role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/requests", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /admin/requests
  describe 'GET /admin/requests' do
    context 'as admin role' do
      it 'admin role returns requests' do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/admin/requests", :headers => default_headers

        expect(json['links']).not_to be_empty
        expect(response).to have_http_status(200)
      end

      it 'approver role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        get "#{api_version}/admin/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end

      it 'regular user role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/admin/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /approver/requests
  describe 'GET /approver/requests' do
    context 'as admin role' do
      it 'admin role returns requests' do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/approver/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end

      it 'approver role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(approver_acls)
        get "#{api_version}/approver/requests", :headers => default_headers

        expect(response).to have_http_status(200)
      end

      it 'regular user role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/approver/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requester/requests
  describe 'GET /requester/requests' do
    context 'as admin role' do
      it 'admin role returns requests' do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/requester/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end

      it 'approver role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(approver_acls)
        get "#{api_version}/requester/requests", :headers => default_headers

        expect(response).to have_http_status(403)
      end

      it 'regular user role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/requester/requests", :headers => default_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for GET /requests?state=
  describe 'GET /requests?state=notified' do
    it 'admin role returns requests' do
      allow(RBAC::Access).to receive(:admin?).and_return(true)
      allow(RBAC::Access).to receive(:approver?).and_return(false)
      get "#{api_version}/requests?filter[state]=notified", :headers => default_headers

      expect(json['links']).not_to be_empty
      expect(json['links']['first']).to match(/offset=0/)
      expect(json['data'].size).to eq(2)
    end

    it 'admin role returns status code 200' do
      allow(RBAC::Access).to receive(:admin?).and_return(true)
      allow(RBAC::Access).to receive(:approver?).and_return(false)
      get "#{api_version}/requests?filter[state]=notified", :headers => default_headers

      expect(json['links']).not_to be_empty
      expect(response).to have_http_status(200)
    end

    it 'approver role returns status code 403' do
      allow(RBAC::Access).to receive(:admin?).and_return(false)
      allow(RBAC::Access).to receive(:approver?).and_return(true)
      get "#{api_version}/requests?filter[state]=notified", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  # Test suite for GET /requests?decision=
  describe 'GET /requests?decision=approved' do
    context 'as admin role' do
      it 'admin role returns requests' do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/requests?filter[decision]=approved", :headers => default_headers

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(2)
      end

      it 'admin role returns status code 200' do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/requests?filter[decision]=approved", :headers => default_headers

        expect(response).to have_http_status(200)
      end

      it 'approver role returns status code 403' do
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        get "#{api_version}/requests?filter[decision]=approved", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /requests?approver=
  describe 'GET /requests?approver=joe@acme.com' do
    before do
      relation = Request.where(:id => user_requests.pluck(:id))
      allow(RequestListByApproverService).to receive(:new).with(username_1).and_return(list_service)
      allow(list_service).to receive(:list).and_return(relation)
    end

    it 'admin role returns requests' do
      allow(RBAC::Access).to receive(:admin?).and_return(true)
      allow(RBAC::Access).to receive(:approver?).and_return(false)
      get "#{api_version}/requests?approver=joe@acme.com", :headers => default_headers

      expect(json['links']).not_to be_empty
      expect(json['links']['first']).to match(/offset=0/)
      expect(json['data'].size).to eq(2)
    end

    it 'admin role returns status code 200' do
      allow(RBAC::Access).to receive(:admin?).and_return(true)
      allow(RBAC::Access).to receive(:approver?).and_return(false)
      get "#{api_version}/requests?approver=joe@acme.com", :headers => default_headers

      expect(response).to have_http_status(200)
    end

    it 'approver role returns status code 403' do
      allow(RBAC::Access).to receive(:admin?).and_return(false)
      allow(RBAC::Access).to receive(:approver?).and_return(false)
      get "#{api_version}/requests?approver=joe@acme.com", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  # Test suite for GET /requests/:id
  describe 'GET /requests/:id' do
    context 'admin role when the record exist' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
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
        allow(RBAC::Access).to receive(:admin?).and_return(true)
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
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(full_approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)

        get "#{api_version}/requests/#{user_requests.first.id}", :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver cannot approve' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(full_approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)

        get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner own the requests' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)

        get "#{api_version}/requests/#{id}", :headers => default_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'owner does not own the requests' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)

        get "#{api_version}/requests/#{requests_with_same_state.first.id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for POST /workflows/:workflow_id/requests
  describe 'POST /workflows/:workflow_id/requests' do
    let(:item) { { 'disk' => '100GB' } }
    let(:valid_attributes) { { :requester_name => '1234', :name => 'Visit Narnia', :content => item, :description => 'desc' } }

    context 'admin role when request attributes are valid' do
      before do
        with_modified_env :AUTO_APPROVAL => 'y' do
          allow(RBAC::Access).to receive(:admin?).and_return(true)
          post "#{api_version}/workflows/#{workflow_id}/requests", :params => valid_attributes, :headers => default_headers
        end
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'admin role when no permission' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        post "#{api_version}/workflows/#{workflow_id}/requests", :params => valid_attributes, :headers => default_headers
      end

      it 'returns status code 500' do
        expect(response).to have_http_status(500)
      end
    end

    context 'approver role' do
      before do
        with_modified_env :AUTO_APPROVAL => 'y' do
          allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return(full_approver_acls)
          allow(RBAC::Access).to receive(:admin?).and_return(false)
          allow(RBAC::Access).to receive(:approver?).and_return(true)
          post "#{api_version}/workflows/#{workflow_id}/requests", :params => valid_attributes, :headers => default_headers
        end
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'owner role' do
      before do
        with_modified_env :AUTO_APPROVAL => 'y' do
          allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal', :limit => 500}, app_name).and_return([])
          allow(RBAC::Access).to receive(:admin?).and_return(false)
          allow(RBAC::Access).to receive(:approver?).and_return(false)
          post "#{api_version}/workflows/#{workflow_id}/requests", :params => valid_attributes, :headers => default_headers
        end
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end
end
