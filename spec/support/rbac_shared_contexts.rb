RSpec.shared_context "approval_rbac_objects" do
  let(:app_name) { 'approval' }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }

  let(:admin_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'admin') }
  let(:admin_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => admin_filter) }
  let(:group_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'group') }
  let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => group_filter) }
  let(:user_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'user') }
  let(:user_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => user_filter) }

  let(:template_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:templates:read", :resource_definitions => [admin_resource_def]) }
  let(:workflow_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:create", :resource_definitions => [admin_resource_def]) }
  let(:workflow_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:read", :resource_definitions => [admin_resource_def]) }
  let(:workflow_update_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:update", :resource_definitions => [admin_resource_def]) }
  let(:workflow_destroy_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:delete", :resource_definitions => [admin_resource_def]) }
  let(:request_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:read", :resource_definitions => [admin_resource_def]) }
  let(:request_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:create", :resource_definitions => [admin_resource_def]) }
  let(:action_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:read", :resource_definitions => [admin_resource_def]) }
  let(:action_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:create", :resource_definitions => [admin_resource_def]) }
  let(:workflow_link_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:link", :resource_definitions => [admin_resource_def]) }
  let(:workflow_unlink_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:unlink", :resource_definitions => [admin_resource_def]) }

  let(:approver_request_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:read", :resource_definitions => [approver_resource_def]) }
  let(:approver_action_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:read", :resource_definitions => [approver_resource_def]) }
  let(:approver_action_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:create", :resource_definitions => [approver_resource_def]) }
  let(:requester_request_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:read", :resource_definitions => [user_resource_def]) }
  let(:requester_request_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:create", :resource_definitions => [user_resource_def]) }
  let(:requester_action_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:create", :resource_definitions => [user_resource_def]) }
  let(:requester_action_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:read", :resource_definitions => [user_resource_def]) }
  let(:requester_workflow_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:read", :resource_definitions => [admin_resource_def]) }

  let(:admin_acls) { [template_read_acl, workflow_create_acl, workflow_read_acl, workflow_destroy_acl, workflow_update_acl, request_create_acl,
                      workflow_link_acl, workflow_unlink_acl, request_read_acl, action_create_acl, action_read_acl] }
  let(:approver_acls) { [approver_request_read_acl, approver_action_create_acl, approver_action_read_acl] }
  let(:requester_acls) { [requester_request_read_acl, requester_request_create_acl, requester_action_create_acl, requester_action_read_acl, requester_workflow_read_acl] }
end
