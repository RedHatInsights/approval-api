RSpec.describe Workflow, type: :model do
  it { should belong_to(:template) }
  it { should have_many(:requests) }

  it { should validate_presence_of(:name) }

  describe '.seed' do
    it 'creates a default workflow' do
      described_class.seed
      expect(described_class.count).to be(1)
      expect(described_class.first.template).to be_nil
    end
  end
end
