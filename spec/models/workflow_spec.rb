require 'rails_helper'

RSpec.describe Workflow, type: :model do
  it { should belong_to(:template) }
  it { should have_many(:requests).dependent(:destroy) }
  it { should validate_presence_of(:name) }
end
