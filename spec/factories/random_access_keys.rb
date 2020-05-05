# spec/factories/random_access_keys.rb
FactoryBot.define do
  factory :random_access_key do
    approver_name  { Faker::Lorem.word }

    request
  end
end
