require 'rails_helper'

RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }

  it { should validate_presence_of(:uuid) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:state) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }
end
