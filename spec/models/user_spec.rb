RSpec.describe User, :type => :model do
  let!(:groups_a) { create_list(:group, 2) }
  let!(:groups_b) { create_list(:group, 3) }
  let!(:workflow_a) { create(:workflow, :groups => groups_a) }
  let!(:workflow_b) { create(:workflow, :groups => groups_b) }
  let(:attribute_a) do
    { :requester => '1234', :name => 'Visit Narnia',
      :content => JSON.generate('{ "disk" => "100GB" }') }
  end
  let(:attribute_b) do
    { :requester => 'abcd', :name => 'Narnia Mary',
      :content => JSON.generate('{ "memory" => "10GB" }') }
  end
  let!(:request_a) { RequestCreateService.new(workflow_a.id).create(attribute_a) }
  let!(:request_b) { RequestCreateService.new(workflow_b.id).create(attribute_b) }
  let!(:adam) { create(:user, :group_ids => [groups_a.first.id, groups_b.first.id, groups_b.last.id]) }
  let!(:fred) { create(:user, :group_ids => [groups_a.first.id, groups_b.second.id]) }
  let!(:john) { create(:user, :group_ids => [groups_a.last.id, groups_b.last.id]) }

  it { should have_many(:usergroups) }
  it { should have_many(:groups).through(:usergroups) }
  it { should validate_presence_of(:email) }

  context 'all associations' do
    it 'when list groups by users' do
      expect(adam.groups.count).to eq(3)
      expect(fred.groups.count).to eq(2)
      expect(john.groups.count).to eq(2)
    end

    it 'when list stages by users' do
      expect(adam.stages.count).to eq(3)
      expect(fred.stages.count).to eq(2)
      expect(john.stages.count).to eq(2)
    end

    it 'when list requests by users' do
      expect(adam.requests.count).to eq(2)
      expect(fred.requests.count).to eq(2)
      expect(john.requests.count).to eq(2)
    end
  end
end
