RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }
  it { should have_many(:stages) }

  it { should validate_presence_of(:requester) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }
end
