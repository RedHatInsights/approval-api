RSpec.describe Group, type: :model do
  it { should have_many(:workflowgroups) }
  it { should have_many(:workflows).through(:workflowgroups) }
  it { should have_many(:stages) }
  it { should have_many(:approvergroups) }
  it { should have_many(:approvers).through(:approvergroups) }

  it { should validate_presence_of(:name) }
end
