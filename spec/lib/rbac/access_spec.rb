describe RBAC::Access do
  include_context "rbac_objects"

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  shared_examples_for "#rbac_role?" do
    it "validate role" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
        svc_obj = rbac_access.process
        expect(svc_obj.acls.count).to eq(acl_count)
        expect(svc_obj.approver_acls.count).to eq(approver_acl_count)
        expect(svc_obj.owner?).to eq(owner_result)
        expect(svc_obj.admin?).to eq(admin_result)
        expect(svc_obj.approver?).to eq(approver_result)
      end
    end
  end

  shared_examples_for "#id_list?" do
    it "id list" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
        svc_obj = rbac_access.process
        expect(svc_obj.approver?).to be_truthy 
        expect(svc_obj.id_list).to eq(resource_id_list)
      end
    end
  end

  context "owner access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [owner_access] }
    let(:owner_result) { true }
    let(:admin_result) { false }
    let(:approver_result) { false }
    let(:acl_count) { 1 }
    let(:approver_acl_count) { 0 }
    it_behaves_like "#rbac_role?"
  end

  context "owner access and admin access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [admin_access, owner_access] }
    let(:admin_result) { true }
    let(:owner_result) { false }
    let(:approver_result) { false }
    let(:acl_count) { 2 }
    let(:approver_acl_count) { 0 }
    it_behaves_like "#rbac_role?"
  end

  context "fetches the array of plans" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [access1] }
    let(:admin_result) { false }
    let(:owner_result) { false }
    let(:approver_result) { false }
    let(:acl_count) { 1 }
    let(:approver_acl_count) { 0 }
    it_behaves_like "#rbac_role?"
  end

  context "approver access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [approver_access] }
    let(:admin_result) { false }
    let(:owner_result) { false }
    let(:approver_result) { true }
    let(:acl_count) { 0 }
    let(:approver_acl_count) { 1 }
    it_behaves_like "#rbac_role?"
  end

  context "id_list" do
    let!(:workflows) { create_list(:workflow, 2) }
    let!(:request1) { create(:request, :workflow_id => workflows.first.id) }
    let!(:request2) { create(:request, :workflow_id => workflows.last.id) }
    let!(:stages1) { create_list(:stage, 2, :state => 'notified', :request_id => request1.id) }
    let!(:stage2) { create(:stage, :state => 'pending', :request_id => request1.id) }
    let!(:stage3) { create(:stage, :state => 'notified', :request_id => request2.id) }
    let!(:actions1) { create_list(:action, 2, :stage_id => stages1.first.id) }
    let!(:actions2) { create_list(:action, 3, :stage_id => stages1.last.id) }

    let(:approver_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflows.first.id) }
    let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter) }
    let(:approver_access) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:approve", :resource_definitions => [approver_resource_def]) }

    describe "id list for request" do
      let(:rbac_access) { described_class.new('requests', 'read') }

      context "when is approver" do
        let(:acls) { [approver_access] }
        let(:resource_id_list) { [request1.id] }
        it_behaves_like "#id_list?"
      end
    end

    describe "id list for stage" do
      let(:rbac_access) { described_class.new('stages', 'read') }

      context "id list for approver" do
        let(:acls) { [approver_access] }
        let(:resource_id_list) { stages1.pluck(:id) }
        it_behaves_like "#id_list?"
      end
    end

    describe "id list for action" do
      let(:rbac_access) { described_class.new('actions', 'read') }

      context "id list for approver" do
        let(:acls) { [approver_access] }
        let(:resource_id_list) { Action.all.pluck(:id) }
        it_behaves_like "#id_list?"
      end
    end
  end

  it "rbac is enabled by default" do
    expect(described_class.enabled?).to be_truthy
  end

  it "rbac is enabled by default" do
    with_modified_env :BYPASS_RBAC => "1" do
      expect(described_class.enabled?).to be_falsey
    end
  end
end
