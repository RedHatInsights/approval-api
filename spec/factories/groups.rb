# spec/factories/groups.rb
FactoryBot.define do
  factory :group do
    name { Faker::Lorem.word }
    email { Faker::Lorem.word }
    message { Faker::Lorem.word }
  end
end
