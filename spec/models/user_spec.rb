RSpec.describe User do
  describe '.find_by_username' do
    before do
      raw_user = double(:raw_user, :username => 'myname', :email => 'a@b', :first_name => 'First', :last_name => 'Last', :is_org_admin => true)
      user_api = double(:user_api)
      expect(user_api).to receive(:get_principal).with('myname').and_return(raw_user)
      expect(RBAC::Service).to receive(:call).with(RBACApiClient::PrincipalApi).and_yield(user_api)
    end

    it 'fetches a group with details from rbac service' do
      expect(described_class.find_by_username('myname')).to have_attributes(
        :username     => 'myname',
        :email        => 'a@b',
        :first_name   => 'First',
        :last_name    => 'Last',
        :'org_admin?' => true
      )
    end
  end

  describe '#groups' do
    before do
      expect(Group).to receive(:all).with('myname').and_return([double(:group1), double(:group2)])
    end

    it 'list all groups' do
      user = User.new
      user.username = 'myname'
      expect(user.groups.size).to eq(2)
    end
  end
end
