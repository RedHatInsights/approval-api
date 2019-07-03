describe RBAC::Roles do
  let(:prefix) { "approval-group-" }
  let(:subject) { described_class.new(prefix) }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:pagination_options) { { :limit => 100, :name => prefix } }

  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:group2) { instance_double(RBACApiClient::GroupOut, :name => 'group2', :uuid => "12345") }
  let(:group3) { instance_double(RBACApiClient::GroupOut, :name => 'group3', :uuid => "45665") }
  let(:groups) { [group1, group2, group3] }
  let(:role1) { instance_double(RBACApiClient::RoleOut, :name => "approval-group-#{group1.uuid}", :uuid => "67899") }
  let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid) }
  let(:role2) { instance_double(RBACApiClient::RoleOut, :name => "approval-group-#{group2.uuid}", :uuid => "55555") }
  let(:roles) { {role1.name => role1.uuid, role2.name => role2.uuid} }
  let(:access1) { instance_double(RBACApiClient::Access, :permission => "approval:actions:read", :resource_definitions => []) }
  let(:acls) { [access1] }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
  end

  it "check roles" do
    allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1, role2])

    expect(subject.instance_variable_get(:@roles).count).to eq(roles.count)
    expect(subject.instance_variable_get(:@roles)[role1.name]).to eq(role1.uuid)
    expect(subject.instance_variable_get(:@roles)[role2.name]).to eq(role2.uuid)
  end

  it "find roles" do
    allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1, role2])
    allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
    allow(api_instance).to receive(:get_role).with(role2.uuid).and_return(nil)

    r1 = subject.find(role1.name)
    expect(r1.name).to eq(role1.name)
    expect(r1.uuid).to eq(role1.uuid)

    r2 = subject.find(role2.name)
    expect(r2).to be_nil
  end

  it "add roles" do
    allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1, role2])
    allow(api_instance).to receive(:create_roles).and_return(role1_detail)

    r = subject.add(role1.name, acls)
    expect(r.name).to eq(role1.name)
  end
end
