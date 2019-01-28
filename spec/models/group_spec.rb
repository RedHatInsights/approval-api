RSpec.describe Group, type: :model do
  it { should have_many(:workflowgroups) }
  it { should have_many(:workflows).through(:workflowgroups) }
  it { should have_many(:stages) }
  it { should have_many(:usergroups) }
  it { should have_many(:users).through(:usergroups) }

  it { should validate_presence_of(:name) }
end
