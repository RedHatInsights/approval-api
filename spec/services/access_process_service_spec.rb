RSpec.describe AccessProcessService do

  let(:subject) { described_class.new }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:group2) { instance_double(RBACApiClient::GroupOut, :name => 'group2', :uuid => "12345") }
  let(:group3) { instance_double(RBACApiClient::GroupOut, :name => 'group3', :uuid => "45665") }
  let(:groups) { [group1, group2, group3] }
  let(:role1) { instance_double(RBACApiClient::RoleOut, :name => "approval-group-#{group1.uuid}", :uuid => "67899") }
  let(:role2) { instance_double(RBACApiClient::RoleOut, :name => "approval-group-#{group2.uuid}", :uuid => "55555") }
  #let(:resource_def1) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter1) }
  #let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid, :access => [access1]) }
  let(:access1) { instance_double(RBACApiClient::Access, :permission => "approval:actions:read", :resource_definitions => []) }
  let(:access2) { instance_double(RBACApiClient::Access, :permission => "approval:actions:create", :resource_definitions => []) }
  let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid) }
  let(:role2_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role2.name, :uuid => role2.uuid, :access => [access1, access2]) }
  let(:pagination_options) { { :limit => 100, :name => "approval-group-" } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    #allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  it "find_role" do
    allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1])
    allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)

    role = subject.find_role(group1.uuid)

    expect(role.name).to eq(role1.name)
    expect(role.uuid).to eq(role1.uuid)
  end
end
