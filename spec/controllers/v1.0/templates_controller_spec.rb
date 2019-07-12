RSpec.describe Api::V1x0::TemplatesController, :type => :request do
  # initialize test data
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }

  let!(:templates) { create_list(:template, 6) }
  let(:template_id) { templates.first.id }

  let(:api_version) { version }

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    before do
      allow(RBAC::Access).to receive(:new).with('templates', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
    end

    context 'when admin role' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      before do
        allow(access_obj).to receive(:not_owned?).and_return(false)
        allow(access_obj).to receive(:not_approvable?).and_return(false)
        allow(access_obj).to receive(:approver_id_list).and_return([])
        allow(access_obj).to receive(:owner_id_list).and_return([])

        get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => request_header
      end

      it 'returns templates' do
        # Note `json` is a custom helper to parse JSON responses
        expect(json['links']).not_to be_empty
        expect(json['links']['first']).to match(/limit=5&offset=0/)
        expect(json['links']['last']).to match(/limit=5&offset=5/)
        expect(json['data'].size).to eq(5)
        expect(response).to have_http_status(200)
      end
    end

    context 'when approver role' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => true, :owner? => false) }

      before { get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => request_header }

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when owner role' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => false, :owner? => true) }

      before { get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => request_header }

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    before do
      allow(RBAC::Access).to receive(:new).with('templates', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
    end

    context 'admin role when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      before do
        allow(access_obj).to receive(:not_owned?).and_return(false)
        allow(access_obj).to receive(:not_approvable?).and_return(false)
        allow(access_obj).to receive(:approver_id_list).and_return([])
        allow(access_obj).to receive(:owner_id_list).and_return([])

        get "#{api_version}/templates/#{template_id}", :headers => request_header
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
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      before do
        allow(access_obj).to receive(:not_owned?).and_return(false)
        allow(access_obj).to receive(:not_approvable?).and_return(false)
        allow(access_obj).to receive(:approver_id_list).and_return([])
        allow(access_obj).to receive(:owner_id_list).and_return([])

        get "#{api_version}/templates/#{template_id}", :headers => request_header
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end

    context 'approver role' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => true, :owner? => false) }

      before { get "#{api_version}/templates/#{template_id}", :headers => request_header }

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner role' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => false, :owner? => true) }

      before { get "#{api_version}/templates/#{template_id}", :headers => request_header }

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
