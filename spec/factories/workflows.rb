# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    name { Faker::StarWars.character }
    template
  end
end
