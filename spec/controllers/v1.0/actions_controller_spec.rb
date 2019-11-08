RSpec.describe Api::V1x0::ActionsController, :type => :request do
  include_context "rbac_objects"
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, :template_id => template.id) }
  let!(:request) { create(:request, :with_context, :workflow_id => workflow.id, :tenant_id => tenant.id) }
  let!(:group_ref) { "990" }
  let!(:stage) { create(:stage, :state => 'notified', :group_ref => group_ref, :request => request, :tenant_id => tenant.id) }
  let(:stage_id) { stage.id }

  let!(:actions) { create_list(:action, 10, :stage_id => stage.id, :tenant_id => tenant.id) }
  let(:id) { actions.first.id }

  let(:filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflow.id) }
  let(:resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter) }
  let(:access) { instance_double(RBACApiClient::Access, :permission => "approval:workflows:approve", :resource_definitions => [resource_def]) }
  let(:full_approver_acls) { approver_acls << access }
  let(:roles_obj) { double }

  let(:api_version) { version }

  before do
    allow(RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  # Test suite for GET /actions/:id
  describe 'GET /actions/:id' do
    context 'admin role when the record exists' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
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
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
        end
      end

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Action/)
      end
    end

    context 'approver role can approve' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => full_approver_acls) }
      let(:approver_group_role) { "approval-group-#{group_ref}" }
      before do
        allow(rs_class).to receive(:paginate).and_return(full_approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, approver_group_role])

        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
        end
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role cannot read' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role])

        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
        end
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'owner role cannot read' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
        end
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "GET /stages/:stage_id/actions" do
    context 'admin role when request attributes are valid' do
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(roles_obj).to receive(:roles).and_return([admin_role])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/stages/#{stage_id}/actions", :headers => default_headers
        end
      end

      it 'returns the actions' do
        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(10)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role can get actions' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => full_approver_acls) }
      let(:approver_group_role) { "approval-group-#{group_ref}" }
      before do
        allow(rs_class).to receive(:paginate).and_return(full_approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, approver_group_role])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/stages/#{stage_id}/actions", :headers => default_headers
        end
      end

      it 'returns the actions' do
        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(10)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'approver role can not get actions' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => approver_acls) }
      let(:approver_group_role) { "approval-group-#{group_ref}" }
      before do
        allow(rs_class).to receive(:paginate).and_return(approver_acls)
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([approver_role, approver_group_role])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/stages/#{stage_id}/actions", :headers => default_headers
        end
      end

      it 'returns status code 200' do
        expect(json['data'].size).to eq(0)
        expect(response).to have_http_status(200)
      end
    end

    context 'owner role can not get actions' do
      let(:access_obj) { instance_double(RBAC::Access, :acl => []) }
      let(:approver_group_role) { "approval-group-#{group_ref}" }
      before do
        allow(rs_class).to receive(:paginate).and_return([])
        allow(access_obj).to receive(:process).and_return(access_obj)
        allow(roles_obj).to receive(:roles).and_return([])
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/stages/#{stage_id}/actions", :headers => default_headers
        end
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  shared_examples_for "validate_operation" do
    it "should validate operation" do
      allow(rs_class).to receive(:paginate).and_return(acls)
      allow(access_obj).to receive(:process).and_return(access_obj)
      allow(roles_obj).to receive(:roles).and_return(roles)
      post "#{api_version}/stages/#{stage_id}/actions", :params => valid_attributes, :headers => default_headers

      expect(response).to have_http_status(code)
    end
  end

  describe 'POST /stages/:stage_id/actions' do
    before do
      allow(Group).to receive(:find)
    end

    context 'admin role when request attributes are valid' do
      let(:acls) { [] }
      let(:access_obj) { instance_double(RBAC::Access, :acl => acls) }
      let(:roles) { [admin_role] }
      let(:valid_attributes) { { :operation => 'cancel', :processed_by => 'abcd' } }
      let(:code) { 201 }

      it_behaves_like "validate_operation"
    end

    context 'approver role far valid operation' do
      let(:acls) { approver_acls }
      let(:access_obj) { instance_double(RBAC::Access, :acl => acls) }
      let(:roles) { [approver_role] }
      let(:valid_attributes) { { :operation => 'approve', :processed_by => 'abcd' } }
      let(:code) { 201 }

      it_behaves_like "validate_operation"
    end

    context 'approver role far invalid operation cancel' do
      let(:acls) { approver_acls }
      let(:access_obj) { instance_double(RBAC::Access, :acl => acls) }
      let(:roles) { [approver_role] }
      let(:valid_attributes) { { :operation => 'cancel', :processed_by => 'abcd' } }
      let(:code) { 403 }

      it_behaves_like "validate_operation"
    end

    context 'owner role for valid operation cancel' do
      let(:acls) { [] }
      let(:access_obj) { instance_double(RBAC::Access, :acl => acls) }
      let(:roles) { [] }
      let(:valid_attributes) { { :operation => 'cancel', :processed_by => 'abcd' } }
      let(:code) { 201 }

      it_behaves_like "validate_operation"
    end

    context 'owner role for invalid operation approve' do
      let(:acls) { [] }
      let(:access_obj) { instance_double(RBAC::Access, :acl => acls) }
      let(:roles) { [] }
      let(:valid_attributes) { { :operation => 'approve', :processed_by => 'abcd' } }
      let(:code) { 403 }

      it_behaves_like "validate_operation"
    end
  end

  describe 'POST /requests/:request_id/actions' do
    let(:req) { create(:request, :with_context, :tenant_id => tenant.id) }

    before do
      allow(Group).to receive(:find)
      allow(rs_class).to receive(:paginate).and_return([])
      allow(roles_obj).to receive(:roles).and_return([])
    end

    context 'when request is actionable' do
      let!(:stage1) { create(:stage, :state => Stage::NOTIFIED_STATE, :request => req, :tenant_id => tenant.id) }
      let!(:stage2) { create(:stage, :state => Stage::PENDING_STATE, :request => req, :tenant_id => tenant.id) }
      let(:valid_attributes) { { :operation => 'cancel', :processed_by => 'abcd' } }

      it 'returns status code 201' do
        post "#{api_version}/requests/#{req.id}/actions", :params => valid_attributes, :headers => default_headers

        expect(req.stages.first.state).to eq(Stage::CANCELED_STATE)
        expect(req.stages.last.state).to eq(Stage::SKIPPED_STATE)
        expect(response).to have_http_status(201)
      end
    end

    context 'when request is not actionable' do
      let!(:stage1) { create(:stage, :state => Stage::FINISHED_STATE, :request => req, :tenant_id => tenant.id) }
      let!(:stage2) { create(:stage, :state => Stage::FINISHED_STATE, :request => req, :tenant_id => tenant.id) }
      let(:valid_attributes) { { :operation => 'notify', :processed_by => 'abcd' } }

      it 'returns status code 422' do
        post "#{api_version}/requests/#{req.id}/actions", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(422)
      end
    end
  end
end
