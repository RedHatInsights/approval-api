RSpec.describe Api::V1x0::TemplatesController, :type => :request do
  include_context "approval_rbac_objects"
  # initialize test data
  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }
  let(:api_version) { version }

  # Test suite for GET /templates
  describe 'GET /templates' do
    context 'when admin role' do
      before { admin_access }

      it 'returns templates' do
        get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => default_headers

        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['data'].size).to eq(5)
        expect(response).to have_http_status(200)
        expect(json['data'].first['metadata']).to have_key("user_capabilities")
      end
    end

    context 'when approver role' do
      before { approver_access }

      it 'returns templates' do
        get "#{api_version}/templates", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'when regular user role' do
      before { user_access }

      it 'returns templates' do
        get "#{api_version}/templates", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    context 'admin role when the record exists' do
      before { admin_access }

      it 'returns the template' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        template = templates.first
        expect(json).not_to be_empty
        expect(json['id']).to eq(template.id.to_s)
        expect(json["metadata"]["user_capabilities"]).to eq("show" => true)
      end

      it 'admin role returns status code 200' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:template_id) { 0 }
      before { admin_access }

      it 'returns status code 404' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        expect(response.body).to match(/Couldn't find Template/)
      end
    end

    context 'approver role' do
      before { approver_access }

      it 'returns status code 403' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'owner role' do
      before { user_access }

      it 'returns status code 403' do
        get "#{api_version}/templates/#{template_id}", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end
end
