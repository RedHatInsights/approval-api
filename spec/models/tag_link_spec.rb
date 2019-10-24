RSpec.describe TagLink, :type => :model do
  let(:workflow) { create(:workflow) }
  let(:a_tag) { {:workflow => workflow, :object_type => 'inventory', :app_name => 'topology', :tag_name => '/approval/workflows/abc'} }

  it { should belong_to(:workflow) }

  context 'duplicated tag link in different tenants' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }

    before { ActsAsTenant.with_tenant(tenant1) { described_class.create(a_tag) } }

    it 'creates the same link in another tenant' do
      ActsAsTenant.with_tenant(tenant2) do
        expect { described_class.create!(a_tag) }.not_to raise_error
      end
    end
  end

  context 'duplicated tag link in the same tenant' do
    let(:tenant) { create(:tenant) }

    before { ActsAsTenant.with_tenant(tenant) { described_class.create(a_tag) } }

    it 'raises an error while attempting to create the same link' do
      ActsAsTenant.with_tenant(tenant) do
        expect { described_class.create!(a_tag) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
