RSpec.describe AccessProcessService do
  let(:subject) { described_class.new }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:role1) { instance_double(RBACApiClient::RoleOut, :name => "approval-group-#{group1.uuid}", :uuid => "67899") }
  let(:access1) { instance_double(RBACApiClient::Access, :permission => "approval:actions:read", :resource_definitions => []) }
  let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid, :access => [access1]) }
  let(:pagination_options) { { :limit => 100, :name => "approval-group-" } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  it "#find_role" do
    allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1])
    allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)

    role = subject.send(:find_role, "approval-group-#{group1.uuid}")

    expect(role.name).to eq(role1.name)
  end
end
