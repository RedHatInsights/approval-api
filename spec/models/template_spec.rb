RSpec.describe Template, type: :model do
  it { should have_many(:workflows) }
  it { should validate_presence_of(:title) }

  describe '.seed' do
    it 'creates a default template' do
      described_class.seed
      expect(described_class.count).to eq(1)
      expect(described_class.first.title).to eq('Basic')
    end
  end
end
