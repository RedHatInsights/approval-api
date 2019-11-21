RSpec.describe Group do
  describe '.find' do
    before do
      raw_group = double(:raw_group, :uuid => 'uuid', :description => 'desc', :name => 'gname', :principals => %w[u1 u2])
      group_api = double(:group_api)
      expect(group_api).to receive(:get_group).with('uuid').and_return(raw_group)
      expect(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(group_api)
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
      expect(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(group_api)
    end

    it 'list all groups' do
      expect(described_class.all('myname').size).to eq(2)
    end
  end
end
