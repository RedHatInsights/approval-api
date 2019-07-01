# spec/factories/requests.rb
FactoryBot.define do
  factory :request do
    items = { Faker::Lorem.word   => Faker::Lorem.word,
             Faker::Lorem.word   => Faker::Lorem.word }
    name           { Faker::Lorem.word }
    requester_name { Faker::Lorem.word }
    owner          { Faker::Lorem.word }
    content        { JSON.generate(items) }
    state          { :pending }
    decision       { :undecided }

    workflow

    trait :with_context do
      after(:create) do |obj|
        obj.update_attributes(:context => RequestSpecHelper.default_request_hash)
      end
    end

    trait :with_tenant do
      tenant
    end
  end
end
