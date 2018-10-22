RSpec.describe Workflow, type: :model do
  it { should belong_to(:template) }
  it { should have_many(:requests) }
  it { should have_many(:workflowgroups) }
  it { should have_many(:groups).through(:workflowgroups) }

  it { should validate_presence_of(:name) }
end
