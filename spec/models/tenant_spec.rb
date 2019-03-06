RSpec.describe Tenant, :type => :model do
  let(:template) { create(:template) }
  let(:tenant)   { create(:tenant) }

  context "without current_tenant" do
    describe "#add_template" do
      it "has no tenant set" do
        ActsAsTenant.with_tenant(nil) do
          expect(template.tenant_id).to be_nil
        end
      end
    end
  end

  context "with current_tenant" do
    describe "#add_template" do
      it "has tenant set by default" do
        ActsAsTenant.with_tenant(tenant) do
          expect(template.tenant_id).to eq tenant.id
        end
      end
    end
  end

  context "with different current_tenant" do
    let(:template_tenant) { create(:template) }
    let(:another_tenant)  { create(:tenant) }

    describe "#add_template" do
      before do
        ActsAsTenant.with_tenant(another_tenant) { template_tenant }
        ActsAsTenant.with_tenant(tenant) { template }
      end

      it "returns template based on current_tenant" do
        ActsAsTenant.with_tenant(nil) { expect(Template.count).to eq(2) }

        ActsAsTenant.with_tenant(tenant) do
          expect(Template.count).to eq 1
          expect(template.tenant_id).to eq tenant.id
          expect(Template.first.id).to eq template.id
        end

        ActsAsTenant.with_tenant(another_tenant) do
          expect(Template.count).to eq 1
          expect(template_tenant.tenant_id).to eq another_tenant.id
          expect(Template.first.id).to eq(template_tenant.id)
        end
      end
    end
  end
end
