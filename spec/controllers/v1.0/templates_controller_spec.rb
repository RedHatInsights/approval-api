RSpec.describe Api::V1x0::TemplatesController, :type => :request do
  include_context "rbac_objects"
  # initialize test data
  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }

  let(:api_version) { version }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    context 'when admin role' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => default_headers
      end

      it 'returns templates' do
        # Note `json` is a custom helper to parse JSON responses
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['data'].size).to eq(5)
        expect(response).to have_http_status(200)
      end
    end

    context 'when approver role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return(approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)
        get "#{api_version}/templates", :headers => default_headers
      end

      it 'returns templates' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when regular user role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)
        get "#{api_version}/templates", :headers => default_headers
      end

      it 'returns templates' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    context 'admin role when the record exists' do
      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        get "#{api_version}/templates/#{template_id}", :headers => default_headers
      end

      it 'returns the template' do
        template = templates.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(template.id.to_s)
        expect(json['created_at']).to eq(template.created_at.iso8601)
      end

      it 'admin role returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:template_id) { 0 }

      before do
        allow(RBAC::Access).to receive(:admin?).and_return(true)
        get "#{api_version}/templates/#{template_id}", :headers => default_headers
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end

    context 'approver role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return(approver_acls)
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(true)

        get "#{api_version}/templates/#{template_id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner role' do
      before do
        allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return([])
        allow(RBAC::Access).to receive(:admin?).and_return(false)
        allow(RBAC::Access).to receive(:approver?).and_return(false)

        get "#{api_version}/templates/#{template_id}", :headers => default_headers
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
