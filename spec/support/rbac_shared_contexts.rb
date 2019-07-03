RSpec.shared_context "rbac_objects" do
  let(:app_name) { 'approval' }
  let(:resource) { "requests" }
  let(:resource_id1) { "1" }
  let(:resource_id2) { "2" }
  let(:resource_id3) { "3" }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:group2) { instance_double(RBACApiClient::GroupOut, :name => 'group2', :uuid => "12345") }
  let(:group3) { instance_double(RBACApiClient::GroupOut, :name => 'group3', :uuid => "45665") }
  let(:role1) { instance_double(RBACApiClient::RoleOut, :name => "#{app_name}-#{resource}-#{resource_id1}-group-#{group1.uuid}", :uuid => "67899") }
  let(:role2) { instance_double(RBACApiClient::RoleOut, :name => "#{app_name}-#{resource}-#{resource_id2}-group-#{group1.uuid}", :uuid => "55555") }
  let(:groups) { [group1, group2, group3] }
  let(:roles) { [role1] }
  let(:policies) { [instance_double(RBACApiClient::PolicyIn, :group => group1, :roles => roles)] }
  let(:filter1) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => resource_id1) }
  let(:resource_def1) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter1) }
  let(:filter2) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => resource_id2) }
  let(:resource_def2) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter2) }
  let(:filter3) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => resource_id3) }
  let(:resource_def3) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter3) }
  let(:access1) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def2]) }
  let(:access3) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:create", :resource_definitions => []) }
  let(:access4) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:create") }
  let(:group_uuids) { [group1.uuid, group2.uuid, group3.uuid] }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }

  let(:approver_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => resource_id1) }
  let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter) }
  let(:approver_access) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:approve", :resource_definitions => [approver_resource_def]) }

  let(:id_value) { '*' }
  let(:id_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => id_value) }
  let(:id_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => id_filter) }
  let(:admin_access) { instance_double(RBACApiClient::Access, :permission => 'approval:requests:read', :resource_definitions => [id_resource_def]) }
end
