RSpec.describe Workflow, :type => :model do
  let(:tenant) { create(:tenant) }
  let(:workflow) { create(:workflow) }

  it { should belong_to(:template) }
  it { should have_many(:requests) }
  it { should have_many(:tag_links) }

  it { should validate_presence_of(:name) }

  describe '#sequence' do
    around(:each) do |example|
      ActsAsTenant.with_tenant(tenant) { example.run }
    end

    before { create_list(:workflow, 5) }

    it 'lists workflows in sequence ascending order' do
      orders = Workflow.pluck(:sequence)
      expect(orders).to eq(orders.sort)
    end

    it 'places newly created workflow to the end of ascending list' do
      old_last = Workflow.last
      expect(create(:workflow).sequence).to eq(old_last.sequence + 1)
    end

    it "auto adjusts newly created workflow's sequence if it is too large" do
      old_last = Workflow.last
      expect(create(:workflow, :sequence => 100).sequence).to eq(old_last.sequence + 1)
    end

    it 'inserts newly created workflow in desired position' do
      old_ids = Workflow.pluck(:id)
      wf = create(:workflow, :sequence => 2)
      expect(wf.sequence).to eq(2)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], wf.id, old_ids[1], old_ids[2], old_ids[3], old_ids[4]])
    end

    it 'fails the creation if the sequence is not positive' do
      expect { Workflow.create!(:name => 'any', :sequence => -2) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'moves a workflow to the top' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[3]).update(:sequence => 1)
      expect(Workflow.pluck(:id)).to eq([old_ids[3], old_ids[0], old_ids[1], old_ids[2], old_ids[4]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4, 5])
    end

    it 'moves a worflow to the bottom' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[3]).update(:sequence => nil)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4, 5])
    end

    it 'moves up a workflow sequence' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[3]).update(:sequence => Workflow.find(old_ids[1]).sequence)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[3], old_ids[1], old_ids[2], old_ids[4]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4, 5])
    end

    it 'moves down a workflow sequence' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[1]).update(:sequence => Workflow.find(old_ids[3]).sequence)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[2], old_ids[3], old_ids[1], old_ids[4]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4, 5])
    end

    it 'does not change sequence when only other attributes changed' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[1]).update(:name => 'newname')
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[3], old_ids[4]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4, 5])
    end

    it 'fails to update a 0 sequence' do
      expect { Workflow.first.update!(:sequence => 0) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'moves up sequences after a workflow is deleted' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[1]).destroy
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[2], old_ids[3], old_ids[4]])
      expect(Workflow.pluck(:sequence)).to eq([1, 2, 3, 4])
    end
  end

  context "with same name in different tenants" do
    let(:another_tenant) { create(:tenant) }
    let(:another_workflow) { create(:workflow, :name => workflow.name) }

    describe "create workflow" do
      before do
        ActsAsTenant.with_tenant(tenant) { workflow }
        ActsAsTenant.with_tenant(another_tenant) { another_workflow }
      end

      it "return created workflows" do
        expect(workflow.name).to eq(another_workflow.name)
      end
    end
  end

  context "with same name in a tenant" do
    describe "create workflow" do
      before do
        ActsAsTenant.with_tenant(tenant) { workflow }
      end

      it "create a workflow with same name" do
        ActsAsTenant.with_tenant(tenant) do
          expect { Workflow.create!(:name => workflow.name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been taken')
        end
      end
    end
  end

  describe '#external_signal? & #external_processing?' do
    context 'no template' do
      it 'has no external_processing' do
        expect(workflow.external_processing?).to be_falsey
        expect(workflow.external_signal?).to be_falsey
      end
    end

    context 'with template' do
      let(:template) { create(:template, :process_setting => {'a' => 'x'}, :signal_setting => {'b' => 'y'}) }
      let(:workflow) { create(:workflow, :template => template) }

      it 'has external_processing' do
        expect(workflow.external_processing?).to be_truthy
        expect(workflow.external_signal?).to be_truthy
      end
    end
  end

  context '.policy_class' do
    it "is WorkflowPolicy" do
      expect(Workflow.policy_class).to eq(WorkflowPolicy)
    end
  end
end
