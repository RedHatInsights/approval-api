RSpec.describe Group, type: :model do
  it { should have_many(:workflowgroups) }
  it { should have_many(:workflows).through(:workflowgroups) }
  it { should have_many(:stages) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:contact_method) }
  it { should validate_presence_of(:contact_setting) }
end
