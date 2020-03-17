RSpec.shared_context "approval_rbac_objects" do
  let(:app_name) { 'approval' }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }

  let(:template_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:templates:read") }
  let(:workflow_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:create") }
  let(:workflow_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:read") }
  let(:workflow_update_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:update") }
  let(:workflow_destroy_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:destroy") }
  let(:request_admin_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:admin") }
  let(:request_approve_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:approve") }
  let(:request_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:read") }
  let(:request_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:requests:create") }
  let(:action_admin_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:admin") }
  let(:action_approve_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:approve") }
  let(:action_read_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:read") }
  let(:action_create_acl) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:create") }

  let(:admin_acls) { [template_read_acl, workflow_create_acl, workflow_read_acl, 
                      workflow_destroy_acl,workflow_update_acl, request_admin_acl, request_create_acl,
                      request_read_acl, action_admin_acl, action_create_acl, action_read_acl] }
  let(:approver_acls) { [request_approve_acl, request_create_acl, request_read_acl, action_approve_acl,
                         action_create_acl, action_read_acl] }
  let(:requester_acls) { [request_read_acl, request_create_acl, action_create_acl] }
end
