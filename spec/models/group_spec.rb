RSpec.describe Group do
  describe '.find' do
    before do
      raw_group = double(:raw_group, :uuid => 'uuid', :description => 'desc', :name => 'gname', :principals => %w[u1 u2])
      group_api = double(:group_api)
      expect(group_api).to receive(:get_group).with('uuid').and_return(raw_group)
      expect(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi, {}).and_yield(group_api)
    end

    it 'fetches a group with details from rbac service' do
      expect(described_class.find('uuid')).to have_attributes(
        :name        => 'gname',
        :description => 'desc',
        :uuid        => 'uuid',
        :users       => %w[u1 u2]
      )
    end
  end

  describe '.all' do
    before do
      raw_groups = [double(:g1, :uuid => 'uuid1').as_null_object, double(:g2, :uuid => 'uuid2').as_null_object]
      raw_list = double(:group_list, :meta => double(:count => 2), :data => raw_groups)
      group_api = double(:group_api)
      expect(group_api).to receive(:list_groups).with(hash_including(:username => 'myname')).and_return(raw_list)
      expect(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi, {}).and_yield(group_api)
    end

    it 'list all groups' do
      expect(described_class.all('myname').size).to eq(2)
    end
  end

  describe '#can_approve?' do
    around do |example|
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        example.call
      end
    end

    let(:ctx) { double(:ctx) }
    let(:role_api) { double(:role_api) }
    let(:roles) { [double(:r1, :uuid => 'uuid1').as_null_object, double(:r2, :uuid => 'uuid2').as_null_object] }
    let(:admin_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'admin') }
    let(:approver_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'group') }
    let(:user_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'scope', :operation => 'equal', :value => 'user') }
    let(:admin_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => admin_filter) }
    let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter) }
    let(:user_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => user_filter) }
    
    let(:admin_action_create_acl) { instance_double(RBACApiClient::Access, :permission => "approval:actions:create", :resource_definitions => [admin_resource_def]) }
    let(:approver_action_create_acl) { instance_double(RBACApiClient::Access, :permission => "approval:actions:create", :resource_definitions => [approver_resource_def]) }
    let(:user_action_create_acl) { instance_double(RBACApiClient::Access, :permission => "approval:actions:create", :resource_definitions => [user_resource_def]) }
    let(:request_create_acl) { instance_double(RBACApiClient::Access, :permission => "approval:requests:create", :resource_definitions => [admin_resource_def]) }

    before do
      allow(ContextService).to receive(:new).and_return(ctx)
      allow(ctx).to receive(:as_org_admin).and_yield
      allow(subject).to receive(:roles).and_return(roles)
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::RoleApi, {}).and_yield(role_api)
      allow(role_api).to receive(:get_role_access).and_return(acls)
    end

    context 'when has admin action create permissions' do
      let(:acls) { double(:acls, :meta => double(:count => 2), :data => [admin_action_create_acl, user_action_create_acl]) }

      it 'should return true' do
        expect(ContextService).to receive(:new).once
        expect(subject.can_approve?).to be_truthy

        subject.can_approve?
        subject.can_approve?
      end
    end

    context 'when has approver action create permissions' do
      let(:acls) { double(:acls, :meta => double(:count => 2), :data => [approver_action_create_acl, user_action_create_acl]) }

      it 'should return true' do
        expect(subject.can_approve?).to be_truthy
      end
    end

    context 'when only has user action create permissions' do
      let(:acls) { double(:acls, :meta => double(:count => 2), :data => [user_action_create_acl, request_create_acl]) }

      it 'should return false' do
        expect(subject.can_approve?).to be_falsey
      end
    end
  end
end
