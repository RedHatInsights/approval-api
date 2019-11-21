RSpec.shared_context "approval_rbac_objects" do
  let(:app_name) { 'approval' }
  let(:resource) { "requests" }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:admin_role) { 'Approval Administrator' }
  let(:approver_role) { 'Approval Approver' }

  let(:approver_access1) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:read") }
  let(:approver_access2) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:read") }
  let(:approver_access3) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:read") }
  let(:approver_access4) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:actions:create") }
  let(:approver_acls) { [approver_access1, approver_access2, approver_access3, approver_access4] }
end
