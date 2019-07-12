describe RBAC::Access do
  include_context "rbac_objects"

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  shared_examples_for "#rbac_role?" do
    it "validate role" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
        allow(Request).to receive(:by_owner).and_return([])
        svc_obj = rbac_access.process
        expect(svc_obj.acls.count).to eq(acl_count)
        expect(svc_obj.approver_acls.count).to eq(approver_acl_count)
        expect(svc_obj.owner_acls.count).to eq(owner_acl_count)
        expect(svc_obj.owner?).to eq(owner_flag)
        expect(svc_obj.admin?).to eq(admin_flag)
        expect(svc_obj.approver?).to eq(approver_flag)
      end
    end
  end

  shared_examples_for "#id_list?" do
    it "id list" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
        allow(Request).to receive(:by_owner).and_return([])
        svc_obj = rbac_access.process
        expect(svc_obj.approver?).to be_truthy
        expect(svc_obj.approver_id_list).to eq(resource_id_list)
      end
    end
  end

  context "when have admin access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [admin_access, access1] }
    let(:owner_flag) { true }
    let(:admin_flag) { true }
    let(:approver_flag) { false }
    let(:acl_count) { 2 }
    let(:owner_acl_count) { 1 }
    let(:approver_acl_count) { 0 }
    it_behaves_like "#rbac_role?"
  end

  context "when have no admin access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [access1] }
    let(:owner_flag) { true }
    let(:admin_flag) { false }
    let(:approver_flag) { false }
    let(:acl_count) { 1 }
    let(:owner_acl_count) { 1 }
    let(:approver_acl_count) { 0 }
    it_behaves_like "#rbac_role?"
  end

  context "when have approver access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [approver_access] }
    let(:owner_flag) { true }
    let(:admin_flag) { false }
    let(:approver_flag) { true }
    let(:acl_count) { 0 }
    let(:owner_acl_count) { 1 }
    let(:approver_acl_count) { 1 }
    it_behaves_like "#rbac_role?"
  end

  context "when have both admin and approver access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [approver_access, admin_access] }
    let(:owner_flag) { true }
    let(:admin_flag) { true }
    let(:approver_flag) { true }
    let(:acl_count) { 1 }
    let(:owner_acl_count) { 1 }
    let(:approver_acl_count) { 1 }
    it_behaves_like "#rbac_role?"
  end

  context "when have both admin and approver access" do
    let(:verb) { "read" }
    let(:rbac_access) { described_class.new(resource, verb) }
    let(:acls) { [approver_access, admin_access] }
    let(:owner_flag) { true }
    let(:admin_flag) { true }
    let(:approver_flag) { true }
    let(:acl_count) { 1 }
    let(:owner_acl_count) { 1 }
    let(:approver_acl_count) { 1 }
    it_behaves_like "#rbac_role?"
  end

  context "id_list" do
    let!(:workflows) { create_list(:workflow, 2) }
    let!(:request1) { create(:request, :workflow_id => workflows.first.id) }
    let!(:request2) { create(:request, :workflow_id => workflows.last.id) }
    let!(:stages1) { create_list(:stage, 2, :state => 'notified', :request_id => request1.id) }
    let!(:stage2) { create(:stage, :state => 'notified', :request_id => request2.id) }
    let!(:actions1) { create_list(:action, 2, :stage_id => stages1.first.id) }
    let!(:actions2) { create_list(:action, 3, :stage_id => stages1.last.id) }

    let(:approver_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflows.first.id) }
    let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter) }
    let(:approver_access) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:approve", :resource_definitions => [approver_resource_def]) }

    describe "for requests" do
      let(:rbac_access) { described_class.new('requests', 'read') }
      let(:acls) { [approver_access] }
      let(:resource_id_list) { [request1.id] }

      it_behaves_like "#id_list?"
    end

    describe "for stages" do
      let(:rbac_access) { described_class.new('stages', 'read') }
      let(:acls) { [approver_access] }
      let(:resource_id_list) { stages1.pluck(:id) }

      it_behaves_like "#id_list?"
    end

    describe "id list for action" do
      let(:rbac_access) { described_class.new('actions', 'read') }
      let(:acls) { [approver_access] }
      let(:resource_id_list) { Action.all.pluck(:id) }

      it_behaves_like "#id_list?"
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
