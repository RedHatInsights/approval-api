RSpec.describe Api::V1x0::GraphqlController, :type => :request do
  include_context "approval_rbac_objects"
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 4, :template => template, :tenant => tenant) }
  let(:id) { workflows.first.id }
  let!(:parent_request) { create(:request, :tenant => tenant) }
  let!(:child_requests) { create_list(:request, 2, :parent_id => parent_request.id, :tenant => tenant) }
  let!(:actions1) { create_list(:action, 2, :request_id => child_requests.first.id, :tenant => tenant) }
  let!(:actions2) { create_list(:action, 2, :request_id => child_requests.second.id, :tenant => tenant) }

  let(:api_version) { version }

  let(:graphql_simple_query) { { 'query' => '{ workflows {  id template_id name  } }' } }
  let(:graphql_id_query) { { 'query' => "{ requests(id: #{id}) { id requests { id parent_id actions { id operation } } description parent_id } }" } }
  let(:graphql_filter_query) { { 'query' => "{ requests(filter: { parent_id: #{parent_request.id} }) { id actions { id operation } description parent_id } }" } }

  let(:headers_with_admin) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
  let(:headers_with_approver) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
  let(:headers_with_requester) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }
  let(:user_request) do
    Insights::API::Common::Request.with_request(default_request_hash) { create(:request, :tenant => tenant) }
  end

  before do
    allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::AccessApi).and_yield(double)
    allow(user).to receive(:graphql_params=).and_return(user)
  end

  describe 'a simple graphql query' do
    let(:graphql_params) { double("graphql_params", :id => nil, :filter => nil) }

    context 'rbac allows' do
      let(:headers) { headers_with_admin }

      before { admin_access }

      it 'selects attributes in workflows' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_simple_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "workflows")
        expect(results.size).to eq(4)
        results.each do |hash|
          expect(hash.keys).to contain_exactly('id', 'template_id', 'name')
        end
      end
    end

    context 'rbac rejects' do
      let(:headers) { headers_with_approver }
      before { approver_access }

      it 'selects attributes in workflows' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_simple_query
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'a graphql query with id params' do
    let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :params => params, :graphql_params => graphql_params) }

    context 'requests with admin role' do
      let(:headers) { headers_with_admin }
      let(:graphql_params) { double("graphql_params", :id => "#{parent_request.id}", :filter => nil) }
      let(:id) { parent_request.id }
      before { admin_access }

      it 'return requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_id_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "requests")
        expect(results.size).to eq(1)
        results.each do |hash|
          expect(hash.keys).to contain_exactly('id', 'requests', 'description', 'parent_id')
          expect(hash['id']).to eq(parent_request.id.to_s)
          expect(hash['requests'].size).to eq(2)
          hash['requests'].each do |req|
            expect(req.keys).to contain_exactly('id', 'parent_id', 'actions')
            expect(req['actions'].size).to eq(2)
          end
        end
      end
    end

    context 'requests with apporver role' do
      let(:headers) { headers_with_approver }
      let(:graphql_params) { double("graphql_params", :id => "#{parent_request.id}", :filter => nil) }
      let(:id) { parent_request.id }
      before { approver_access }

      it 'return 403' do
        allow(user).to receive(:group_uuids).and_return([])

        post "#{api_version}/graphql", :headers => headers, :params => graphql_id_query
        expect(response.status).to eq(403)
      end
    end

    context 'requests with user role' do
      let(:headers) { headers_with_requester }
      let(:graphql_params) { double("graphql_params", :id => "#{parent_request.id}", :filter => nil) }
      let(:id) { parent_request.id }
      before { user_access }

      it 'return empty requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_id_query

        expect(response.status).to eq(403)
      end
    end

    context 'requests with user role' do
      let(:headers) { headers_with_requester }
      let(:graphql_params) { double("graphql_params", :id => "#{user_request.id}", :filter => nil) }
      let(:id) { user_request.id }
      before { user_access }

      it 'return empty requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_id_query

        expect(response.status).to eq(200)
      end
    end
  end

  describe 'a graphql query with filter params' do
    let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :params => params, :graphql_params => graphql_params) }
    let(:graphql_params) { double("graphql_params", :id => nil, :filter => { :parent_id => "#{parent_request.id}" }) }

    context 'requests with admin role' do
      let(:headers) { headers_with_admin }
      before { admin_access }

      it 'return requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_filter_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "requests")
        expect(results.size).to eq(2)
        results.each do |hash|
          expect(hash.keys).to contain_exactly('id', 'actions', 'description', 'parent_id')
        end
      end
    end
  end
end
