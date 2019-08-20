RSpec.describe Api::V1x0::ActionsController, :type => :request do
  include_context "rbac_objects"

  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let(:request) { create(:request, :with_context, :tenant_id => tenant.id) }
  let!(:group_ref) { "990" }
  let!(:stage) { create(:stage, :group_ref => group_ref, :request => request, :tenant_id => tenant.id) }
  let(:stage_id) { stage.id }

  let!(:actions) { create_list(:action, 10, :stage_id => stage.id, :tenant_id => tenant.id) }
  let(:id) { actions.first.id }

  let(:api_version) { version }

  # Test suite for GET /actions/:id
  describe 'GET /actions/:id' do
    before do
      allow(RBAC::Access).to receive(:new).with('actions', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
    end

    context 'admin role when the record exists' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }
      before do
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => request_header
        end
      end

      it 'returns the action' do
        action = actions.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(action.id.to_s)
        expect(json['created_at']).to eq(action.created_at.iso8601)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'admin role when the record does not exist' do
      let!(:id) { 0 }
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }
      before do
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => request_header
        end
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Action/)
      end
    end

    context 'approver role can read' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => false, :approver? => true, :owner? => false) }
      before do
        allow(access_obj).to receive(:not_owned?).and_return(true)
        allow(access_obj).to receive(:not_approvable?).and_return(false)

        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => request_header
        end
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role cannot read' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => false, :approver? => true, :owner? => false) }
      before do
        allow(access_obj).to receive(:not_owned?).and_return(true)
        allow(access_obj).to receive(:not_approvable?).and_return(true)

        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => request_header
        end
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner role cannot read' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => false, :owner? => true) }
      before do
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => request_header
        end
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /stages/:stage_id/actions' do
    let(:valid_attributes) { { :operation => 'notify', :processed_by => 'abcd' } }
    before do
      allow(Group).to receive(:find)
      allow(RBAC::Access).to receive(:new).with('actions', 'create').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
    end

    context 'admin role when request attributes are valid' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

      it 'returns status code 201' do
        post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes, :headers => request_header

        expect(response).to have_http_status(201)
      end
    end

    context 'approver role when request attributes are valid' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => false, :approver? => true, :owner? => false) }

      it 'returns status code 201' do
        post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes, :headers => request_header

        expect(response).to have_http_status(201)
      end
    end

    context 'owner role when request attributes are valid' do
      let(:access_obj) { instance_double(RBAC::Access, :accessible? => false, :admin? => false, :approver? => false, :owner? => true) }

      it 'returns status code 403' do
        post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes, :headers => request_header

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /requests/:request_id/actions' do
    let(:req) { create(:request, :with_context, :tenant_id => tenant.id) }
    let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

    before do
      allow(RBAC::Access).to receive(:new).with('actions', 'create').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      allow(Group).to receive(:find)
    end

    context 'when request is actionable' do
      let!(:stage1) { create(:stage, :state => Stage::NOTIFIED_STATE, :request => req, :tenant_id => tenant.id) }
      let!(:stage2) { create(:stage, :state => Stage::PENDING_STATE, :request => req, :tenant_id => tenant.id) }
      let(:valid_attributes) { { :operation => 'cancel', :processed_by => 'abcd' } }

      it 'returns status code 201' do
        post "#{api_version}/requests/#{req.id}/actions", :params => valid_attributes, :headers => request_header

        expect(req.stages.first.state).to eq(Stage::CANCELED_STATE)
        expect(req.stages.last.state).to eq(Stage::SKIPPED_STATE)
        expect(response).to have_http_status(201)
      end
    end

    context 'when request is not actionable' do
      let!(:stage1) { create(:stage, :state => Stage::FINISHED_STATE, :request => req, :tenant_id => tenant.id) }
      let!(:stage2) { create(:stage, :state => Stage::FINISHED_STATE, :request => req, :tenant_id => tenant.id) }
      let(:valid_attributes) { { :operation => 'notify', :processed_by => 'abcd' } }

      it 'returns status code 500' do
        post "#{api_version}/requests/#{req.id}/actions", :params => valid_attributes, :headers => request_header

        expect(response).to have_http_status(500)
      end
    end
  end
end
