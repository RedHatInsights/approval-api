require 'rails_helper'

RSpec.describe Template, type: :model do
  # ensure Todo model has a 1:m relationship with the Item model
  it { should have_many(:workflows).dependent(:destroy) }
  # Validation tests
  # ensure columns title and created_by are present before saving
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:created_by) }
end
