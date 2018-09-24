# spec/factories/requests.rb
FactoryBot.define do
  factory :request do
    name         { Faker::Lorem.word }
    content      { Faker::Lorem.word }
    uuid         { Faker::Lorem.word }
    requested_by { Faker::Lorem.word }
  end
end
