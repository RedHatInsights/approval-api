RSpec.describe Api::V1x0::GraphqlController, :type => :request do
  include_context "approval_rbac_objects"
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 4, :template => template, :tenant => tenant) }
  let(:id) { workflows.first.id }
  let!(:parent_request) { create(:request) }
  let!(:child_requests) { create_list(:request, 2, :parent_id => parent_request.id, :tenant => tenant) }
  let!(:actions1) { create_list(:action, 2, :request_id => child_requests.first.id, :tenant => tenant) }
  let!(:actions2) { create_list(:action, 2, :request_id => child_requests.second.id, :tenant => tenant) }

  let(:api_version) { version }

  let(:graphql_source_query) { { 'query' => '{ workflows {  id template_id name  } }' } }
  let(:graphql_requests_query) { { 'query' => "{ requests(filter: { parent_id: #{parent_request.id} }) { id actions { id operation } description parent_id } }" } }

  let(:headers_with_admin) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
  let(:headers_with_approver) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
  let(:headers_with_requester) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }

  before { allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::AccessApi).and_yield(double) }

  describe 'a simple graphql query' do
    context 'rbac allows' do
      let(:headers) { headers_with_admin }
      before { admin_access }

      it 'selects attributes in workflows' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_source_query

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
        post "#{api_version}/graphql", :headers => headers, :params => graphql_source_query
        expect(response.status).to eq(403)
      end
    end

    context 'requests with admin role' do
      let(:headers) { headers_with_admin }
      before { admin_access }

      it 'return requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_requests_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "requests")
        expect(results.size).to eq(2)
        results.each do |hash|
          expect(hash.keys).to contain_exactly('id', 'actions', 'description', 'parent_id')
          expect(hash['actions'].size).to eq(2)
        end
      end
    end

    context 'requests with apporver role' do
      let(:headers) { headers_with_approver }
      before { approver_access }

      it 'return 403' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_requests_query
        expect(response.status).to eq(403)
      end
    end

    context 'requests with user role' do
      let(:headers) { headers_with_requester }
      before { user_access }

      it 'return empty requests' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_requests_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "requests")
        expect(results.size).to eq(0)
      end
    end
  end
end
