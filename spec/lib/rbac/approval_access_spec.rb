describe RBAC::ApprovalAccess do
  include_context "rbac_objects"
  let!(:workflows) { create_list(:workflow, 2) }
  let!(:request) do
    ManageIQ::API::Common::Request.with_request(:headers => default_headers, :original_url => "localhost/approval") do
      create(:request, :workflow_id => workflows.first.id)
    end
  end
  #let!(:request) { create(:request, :workflow_id => workflows.first.id, :owner => 'adam') }
  let!(:requests) { create_list(:request, 2, :workflow_id => workflows.last.id, :owner => 'adam') }

  let(:filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflows.first.id) }
  let(:resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter) }
  let(:access) { instance_double(RBACApiClient::Access, :permission => "approval:workflows:approve", :resource_definitions => [resource_def]) }
  let(:full_approver_acls) { approver_acls << access }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  shared_examples_for ".resource_accessible" do
    it "validate accessible" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).and_return(acls)

        expect(RBAC::ApprovalAccess.new(res, verb).resource_accessible?).to equal(accessible)
      end
    end
  end

  shared_examples_for ".resource_instance_accessible" do
    it "validate instance accessible" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).and_return(acls)
        ManageIQ::API::Common::Request.with_request(default_request_hash) do
          expect(RBAC::ApprovalAccess.new(res, verb).resource_instance_accessible?(res, id)).to equal(accessible)
        end
      end
    end
  end

  context "as admin role when validating resource_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(true)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "create" }
    let(:res) { "requests" }
    let(:accessible) { true }
    let(:acls) { [] }
    it_behaves_like ".resource_accessible"
  end

  context "as approver role can access resource when validating resource_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(true)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:accessible) { true }
    let(:acls) { approver_acls }
    it_behaves_like ".resource_accessible"
  end

  context "as approver role can not access resource when validating resource_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(true)
    end
    let(:verb) { "read" }
    let(:res) { "templates" }
    let(:accessible) { false }
    let(:acls) { approver_acls }
    it_behaves_like ".resource_accessible"
  end

  context "as regular user role can access resource when validating resource_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:accessible) { true }
    let(:acls) { [] }
    it_behaves_like ".resource_accessible"
  end

  context "as regular user role can not access resource when validating resource_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "read" }
    let(:res) { "actions" }
    let(:accessible) { false }
    let(:acls) { [] }
    it_behaves_like ".resource_accessible"
  end

  context "as admin role when validating resource_instance_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(true)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "create" }
    let(:res) { "requests" }
    let(:id) {}
    let(:accessible) { true }
    let(:acls) { [] }
    it_behaves_like ".resource_instance_accessible"
  end

  context "as approver role can not access resource instance when validating resource_instance_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(true)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:id) { requests.first.id }
    let(:accessible) { false }
    let(:acls) { full_approver_acls }
    it_behaves_like ".resource_instance_accessible"
  end

  context "as approver role can access resource instance when validating resource_instance_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(true)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:id) { request.id }
    let(:accessible) { true }
    let(:acls) { full_approver_acls }
    it_behaves_like ".resource_instance_accessible"
  end

  context "as regular user role can access resource instance when validating resource_instance_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:id) { request.id }
    let(:accessible) { true }
    let(:acls) { [] }
    it_behaves_like ".resource_instance_accessible"
  end

  context "as regular user role can not access resource instance when validating resource_instance_accessible" do
    before do
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::ADMIN_ROLE).and_return(false)
      allow(RBAC::Roles).to receive(:assigned_role?).with(RBAC::ApprovalAccess::APPROVER_ROLE).and_return(false)
    end
    let(:verb) { "read" }
    let(:res) { "requests" }
    let(:id) { requests.first.id }
    let(:accessible) { false }
    let(:acls) { [] }
    it_behaves_like ".resource_instance_accessible"
  end

  it "rbac is enabled by default" do
    expect(described_class.enabled?).to be_truthy
  end

  it "rbac is disabled by env variable" do
    with_modified_env :BYPASS_RBAC => "1" do
      expect(described_class.enabled?).to be_falsey
    end
  end
end
