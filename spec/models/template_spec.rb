RSpec.describe Template, type: :model do
  it { should have_many(:workflows) }
  it { should validate_presence_of(:title) }
end
