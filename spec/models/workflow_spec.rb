RSpec.describe Workflow, :type => :model do
  let(:tenant) { create(:tenant) }
  let(:workflow) { create(:workflow) }

  it { should belong_to(:template) }
  it { should have_many(:requests) }

  it { should validate_presence_of(:name) }

  describe '.seed' do
    it 'creates a default workflow' do
      described_class.seed
      expect(described_class.count).to be(1)
      expect(described_class.first.template).to be_nil
    end

    it 'cannot be destroyed' do
      described_class.seed
      expect { described_class.default_workflow.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end

  context "with same name in different tenants" do
    let(:another_tenant) { create(:tenant) }
    let(:another_workflow) do
      create(:workflow, :name => workflow.name)
    end

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

  context "with same name in no tenant" do
    describe "create workflow" do
      before { workflow }

      it "create a workflow with same name" do
        ActsAsTenant.with_tenant(tenant) do
          expect { Workflow.create!(:name => workflow.name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been taken')
        end
      end
    end
  end
end
