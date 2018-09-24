# spec/factories/templates.rb
FactoryBot.define do
  factory :template do
    title { Faker::Lorem.word }
    description { Faker::Lorem.word }
    created_by { Faker::Number.number(10) }
  end
end
