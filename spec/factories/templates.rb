# spec/factories/templates.rb
FactoryBot.define do
  factory :template do
    title { Faker::Lorem.word }
    description { Faker::Lorem.word }
  end
end
