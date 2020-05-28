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

  describe '#deletable?' do
    shared_examples_for "undeletable_states" do |state|
      it "returns false for #{state}" do
        request = create(:request, :workflow => workflow, :state => state)
        expect(workflow.deletable?).to eq(false)
      end
    end
    
    shared_examples_for "deletable_states" do |state|
      it "returns true for #{state}" do
        request = create(:request, :workflow => workflow, :state => state)
        expect(workflow.deletable?).to eq(true)
      end
    end

    (Request::STATES - Request::FINISHED_STATES).each do |state|
      it_behaves_like "undeletable_states", state
    end

    Request::FINISHED_STATES.each do |state|
      it_behaves_like "deletable_states", state
    end
  end

  describe '#destroy' do
    let!(:taglink) { create(:tag_link, :workflow => workflow) }

    context 'when without associated request' do
      it 'deletes workflow' do
        expect(TagLink.count).to eq(1)
        workflow.destroy

        expect(workflow).to be_destroyed
        expect(TagLink.count).to eq(0)
      end
    end

    context 'when associated with requests' do
      let(:event_service) { double('event_service') }

      it "is not deletable" do
        allow(workflow).to receive(:deletable?).and_return(false)

        request = create(:request, :workflow => workflow)

        expect(TagLink.count).to eq(1)
        expect { workflow.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(workflow).not_to be_destroyed
        expect(request.workflow_id).to eq(workflow.id)
        expect(TagLink.count).to eq(1)
      end

      it "is deletable" do
        allow(workflow).to receive(:deletable?).and_return(true)
        allow(EventService).to receive(:new).and_return(event_service)

        request = create(:request, :workflow => workflow, :state => Request::COMPLETED_STATE)

        expect(event_service).to receive(:workflow_deleted)
        expect(TagLink.count).to eq(1)
        workflow.destroy
        request.reload
        expect(workflow).to be_destroyed
        expect(request.workflow_id).to be_nil
        expect(TagLink.count).to eq(0)
      end
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
