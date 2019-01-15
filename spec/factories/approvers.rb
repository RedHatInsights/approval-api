# spec/factories/approvers.rb
FactoryBot.define do
  factory :approver do
    email      { Faker::Internet.email }
    first_name { Faker::Lorem.word }
    last_name  { Faker::Lorem.word }
  end
end
