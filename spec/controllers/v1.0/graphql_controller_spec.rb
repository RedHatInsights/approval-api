RSpec.describe Api::V1x0::GraphqlController, :type => :request do
  let(:encoded_user) { encoded_user_hash }
  let(:headers) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 4, :template_id => template.id) }
  let(:id) { workflows.first.id }

  let(:api_version) { version }

  let(:graphql_source_query) { { 'query' => '{ workflows {  id template_id name  } }' } }

  describe 'a simple graphql query' do
    before { post("#{api_version}/graphql", :headers => headers, :params => graphql_source_query) }

    it 'selects attributes in workflows' do
      expect(response.status).to eq(200)

      results = JSON.parse(response.body).fetch_path("data", "workflows")
      expect(results.size).to eq(4)
      results.each do |hash|
        expect(hash.keys).to contain_exactly('id', 'template_id', 'name')
      end
    end
  end
end
