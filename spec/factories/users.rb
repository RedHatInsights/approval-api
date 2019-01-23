# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email      { Faker::Internet.email }
    first_name { Faker::Lorem.word }
    last_name  { Faker::Lorem.word }
  end
end
