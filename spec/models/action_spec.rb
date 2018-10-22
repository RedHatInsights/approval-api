RSpec.describe Action, type: :model do
  it { should belong_to(:stage) }
  it { should validate_presence_of(:processed_by) }
end
