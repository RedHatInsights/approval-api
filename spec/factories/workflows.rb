# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    name { Faker::Lorem.word }
    template
  end
end
