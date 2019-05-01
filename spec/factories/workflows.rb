# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    name { Faker::Name.unique.name }
    template
  end
end
