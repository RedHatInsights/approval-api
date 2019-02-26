RSpec.describe Stage, type: :model do
  it { should belong_to(:request) }
end
