RSpec.describe User do
  let(:user_api) { double(:user_api) }
  let(:raw_user) do
    double(:raw_user, :username => 'myname', :email => 'a@b', :first_name => 'First', :last_name => 'Last', :is_org_admin => true)
  end

  describe '.find_by_username' do
    it 'fetches a group with details from rbac service' do
      expect(user_api).to receive(:get_principal).with('myname').and_return(raw_user)
      expect(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::PrincipalApi, {}).and_yield(user_api)
      expect(described_class.find_by_username('myname')).to have_attributes(
        :username     => 'myname',
        :email        => 'a@b',
        :first_name   => 'First',
        :last_name    => 'Last',
        :'org_admin?' => true
      )
    end
  end

  describe '.all' do
    let(:raw_users) { [double(:u1, :username => 'u1').as_null_object, double(:u2, :username => 'u2').as_null_object] }
    let(:raw_list) { double(:user_list, :meta => double(:count => 2), :data => raw_users) }

    before do
      allow(user_api).to receive(:list_principals).and_return(raw_list)
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::PrincipalApi, {}).and_yield(user_api)
    end

    it 'returns all users with same username' do
      users = described_class.all
      expect(users.size).to eq(2)
    end
  end

  describe '#org_admin?' do
    before do
      allow(user_api).to receive(:get_principal).with('myname').and_return(raw_user)
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::PrincipalApi, {}).and_yield(user_api)
    end

    it 'returns true' do
      user = described_class.find_by_username('myname')

      expect(user.org_admin?).to be_truthy
    end
  end

  describe '#groups' do
    before do
      expect(Group).to receive(:all).with('myname').and_return([double(:group1), double(:group2)])
    end

    it 'lists all groups' do
      user = User.new
      user.username = 'myname'
      expect(user.groups.size).to eq(2)
    end
  end
end
