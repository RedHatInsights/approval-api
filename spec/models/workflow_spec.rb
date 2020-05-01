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
      expect(create(:workflow).sequence).to be > old_last.sequence
    end

    it 'moves up an workflow sequence' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[3]).update(:sequence => Workflow.find(old_ids[1]).sequence)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[3], old_ids[1], old_ids[2], old_ids[4]])
    end

    it 'moves down an workflow sequence' do
      old_ids = Workflow.pluck(:id)
      Workflow.find(old_ids[1]).update(:sequence => Workflow.find(old_ids[3]).sequence)
      expect(Workflow.pluck(:id)).to eq([old_ids[0], old_ids[2], old_ids[3], old_ids[1], old_ids[4]])
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
