RSpec.describe Workflow, :type => :model do
  let(:tenant) { create(:tenant) }
  let(:workflow) { create(:workflow) }

  it { should belong_to(:template) }
  it { should have_many(:requests) }
  it { should have_many(:tag_links) }

  it { should validate_presence_of(:name) }

  describe '#move_internal_sequence' do
    around(:each) do |example|
      ActsAsTenant.with_tenant(tenant) { example.run }
    end

    let(:old_ids) do
      create_list(:workflow, 5)
      Workflow.pluck(:id)
    end

    it 'moves up sequence in range' do
      Workflow.find(old_ids[4]).move_internal_sequence(-2)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[4], old_ids[2], old_ids[3]])
    end

    it 'moves down sequence in range' do
      Workflow.find(old_ids[1]).move_internal_sequence(2)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[2], old_ids[3], old_ids[1], old_ids[4]])
    end

    it 'moves up to top' do
      Workflow.find(old_ids[2]).move_internal_sequence(-2)
      expect(Workflow.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down to bottom' do
      Workflow.find(old_ids[3]).move_internal_sequence(1)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'moves up beyond range' do
      Workflow.find(old_ids[2]).move_internal_sequence(-20)
      expect(Workflow.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down beyond range' do
      Workflow.find(old_ids[3]).move_internal_sequence(20)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'moves up to top explicitly' do
      Workflow.find(old_ids[2]).move_internal_sequence(-Float::INFINITY)
      expect(Workflow.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down to bottom explicitly' do
      Workflow.find(old_ids[3]).move_internal_sequence(Float::INFINITY)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'places the newly created workflow to the end of list' do
      old_ids
      nw = Workflow.create(:name => 'new workflow')
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[3], old_ids[4], nw.id])
    end

    it 'maintains sorting after one workflow is removed' do
      Workflow.find(old_ids[3]).destroy
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4]])
    end
  end

  describe '#positive_internal_sequence' do
    it 'validates the internal_sequence must be positive' do
      expect { workflow.update!(:internal_sequence => -1) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Internal sequence must be positive')
    end
  end

  describe '#deletable?' do
    shared_examples_for "undeletable_states" do |state|
      it "returns false for #{state}" do
        create(:request, :workflow => workflow, :state => state)
        expect(workflow.deletable?).to eq(false)
      end
    end

    shared_examples_for "deletable_states" do |state|
      it "returns true for #{state}" do
        create(:request, :workflow => workflow, :state => state)
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

        request = create(:request, :workflow => workflow, :state => Request::COMPLETED_STATE)

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
