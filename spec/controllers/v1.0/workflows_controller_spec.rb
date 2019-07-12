RSpec.describe Api::V1x0::WorkflowsController, :type => :request do
  # Initialize the test data
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 16, :template_id => template.id) }
  let(:id) { workflows.first.id }

  let(:api_version) { version }

  describe 'GET /templates/:template_id/workflows' do
    before { get "#{api_version}/templates/#{template_id}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => request_header }

    context 'when template exists' do
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

    context 'when template does not exist' do
      let!(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end

  describe 'GET /workflows' do
    before { get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => request_header }

    context 'when no relate wiht template'
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

  describe "GET /workflows with filter" do
    before do
      get "#{api_version}/workflows?filter[id]=#{id}", :params => { :limit => 5, :offset => 0 }, :headers => request_header
    end

    it 'returns only the filtered result' do
      expect(json["meta"]["count"]).to eq 1
      expect(json["data"].first["id"]).to eq id.to_s
    end
  end

  describe 'GET /workflows/:id' do
    before { get "#{api_version}/workflows/#{id}", :headers => request_header }

    context 'when the record exists' do
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

    context 'when the record does not exist' do
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
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

    context 'when request attributes are valid' do
      before { post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => request_header }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when a request with missing parameter' do
      before { post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes.slice(:description, :group_refs), :headers => request_header }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed:/)
      end
    end
  end

  # Test suite for PATCH /workflows/:id
  describe 'PATCH /workflows/:id' do
    let(:valid_attributes) { { :name => 'Mozart' } }

    before { patch "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => request_header }

    context 'when item exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the item' do
        updated_item = Workflow.find(id)
        expect(updated_item.name).to match(/Mozart/)
      end
    end

    context 'when the item does not exist' do
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for DELETE /workflows/:id
  describe 'DELETE /workflows/:id' do
    before { delete "#{api_version}/workflows/#{id}", :headers => request_header }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'DELETE /workflows/:id with associated request' do
    let!(:request) { create(:request, :workflow => workflows.first) }
    before { delete "#{api_version}/workflows/#{id}", :headers => request_header }

    it 'returns status code 403' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'DELETE /workflows/:id of default workflow' do
    before do
      Workflow.seed
      delete "#{api_version}/workflows/#{Workflow.default_workflow.id}", :headers => request_header
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

    it "fails if the hybrid_cloud entitlement is false" do
      headers = { 'x-rh-identity' => encoded_user_hash(false_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => headers

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the request through if entitlements isn't present" do
      headers = { 'x-rh-identity' => encoded_user_hash(missing_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/workflows", :params => { :limit => 5, :offset => 0 }, :headers => headers

      expect(response).to have_http_status(:ok)
    end
  end
end
