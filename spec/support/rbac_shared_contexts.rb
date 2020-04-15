RSpec.shared_context "approval_rbac_objects" do
  let(:app_name) { 'approval' }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }

  let(:params) { {} }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access) }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :params => params) }

  let(:admin_access) do
    allow(UserContext).to receive(:new).and_return(user)
    allow(user).to receive(:access).and_return(access)
    allow(access).to receive(:accessible?).and_return(true)
    allow(access).to receive(:scopes).and_return(['admin'])
  end

  let(:approver_access) do
    allow(UserContext).to receive(:new).and_return(user)
    allow(user).to receive(:access).and_return(access)
    allow(access).to receive(:scopes).and_return(['group'])
    allow(access).to receive(:accessible?).with('requests', 'read').and_return(true)
    allow(access).to receive(:accessible?).with('actions', 'create').and_return(true)
    allow(access).to receive(:accessible?).with('actions', 'read').and_return(true)
    allow(access).to receive(:accessible?).with('templates', 'read').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'create').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'read').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'delete').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'update').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'link').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'unlink').and_return(false)
    allow(access).to receive(:accessible?).with('requests', 'create').and_return(false)
  end

  let(:user_access) do
    allow(UserContext).to receive(:new).and_return(user)
    allow(user).to receive(:access).and_return(access)
    allow(access).to receive(:scopes).and_return(['user'])
    allow(access).to receive(:accessible?).with('requests', 'read').and_return(true)
    allow(access).to receive(:accessible?).with('actions', 'create').and_return(true)
    allow(access).to receive(:accessible?).with('actions', 'read').and_return(true)
    allow(access).to receive(:accessible?).with('templates', 'read').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'create').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'read').and_return(true)
    allow(access).to receive(:accessible?).with('workflows', 'delete').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'update').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'link').and_return(false)
    allow(access).to receive(:accessible?).with('workflows', 'unlink').and_return(false)
    allow(access).to receive(:accessible?).with('requests', 'create').and_return(true)
  end
end
