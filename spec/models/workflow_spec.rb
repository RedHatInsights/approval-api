RSpec.describe Workflow, :type => :model do
  let(:tenant) { create(:tenant) }
  let(:workflow) { create(:workflow, :name => "same") }

  it { should belong_to(:template) }
  it { should have_many(:requests) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to(:tenant_id) }

  describe '.seed' do
    it 'creates a default workflow' do
      described_class.seed
      expect(described_class.count).to be(1)
      expect(described_class.first.template).to be_nil
    end
  end

  context "with different current tenant" do
    let(:another_tenant) { create(:tenant) }
    let(:workflow_tenant) { create(:workflow, :name => "same") }

    describe "create workflow" do
      before do
        ActsAsTenant.with_tenant(another_tenant) { workflow_tenant }
        ActsAsTenant.with_tenant(tenant) { workflow }
      end

      it "return created workflows" do
        ActsAsTenant.with_tenant(nil) { expect(Workflow.count).to eq(2) }
        expect(workflow.name).to eq("same")
        expect(workflow_tenant.name).to eq("same")
      end
    end
  end

  context "with the same tenant" do
    describe "create workflow" do
      before do
        ActsAsTenant.with_tenant(tenant) { workflow }
      end

      it "create a workflow with same name" do
        ActsAsTenant.with_tenant(tenant) do
          expect { Workflow.create!(:name => "same") }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been taken')
        end
      end
    end
  end
end
