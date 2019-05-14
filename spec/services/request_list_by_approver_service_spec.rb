RSpec.describe RequestListByApproverService do
  let(:tenant) { create(:tenant, :external_tenant => 369_233) }

  let(:username_1) { "jdoe@acme.com" }
  let(:username_2) { "john@acme.com" }
  let(:username_3) { "joe@acme.com" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "234") }

  let!(:workflow_1) { create(:workflow, :name => 'workflow_1', :group_refs => [group1.uuid, group2.uuid]) }
  let!(:workflow_2) { create(:workflow, :name => 'workflow_2', :group_refs => [group2.uuid]) }
  let!(:workflow_3) { create(:workflow, :name => 'workflow_3', :group_refs => [group1.uuid]) }

  let!(:requests_with_workflow_1) { create_list(:request, 2, :workflow_id => workflow_1.id, :tenant_id => tenant.id) }
  let!(:requests_with_workflow_2) { create_list(:request, 3, :workflow_id => workflow_2.id, :tenant_id => tenant.id) }
  let!(:requests_with_workflow_3) { create_list(:request, 4, :workflow_id => workflow_3.id, :tenant_id => tenant.id) }

  before do
    allow(Group).to receive(:all).with(username_1).and_return([group1, group2])
    allow(Group).to receive(:all).with(username_2).and_return([group2])
    allow(Group).to receive(:all).with(username_3).and_return([group1])
  end

  describe 'returns requests' do
    it 'by username_1' do
      expect(RequestListByApproverService.new(username_1).list.size).to eq(9)
    end

    it 'by username_2' do
      expect(RequestListByApproverService.new(username_2).list.size).to eq(5)
    end

    it 'by username_3' do
      expect(RequestListByApproverService.new(username_3).list.size).to eq(6)
    end
  end
end
