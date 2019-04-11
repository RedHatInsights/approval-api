# spec/factories/requests.rb
FactoryBot.define do
  factory :request do
    items = { Faker::Lorem.word   => Faker::Lorem.word,
             Faker::Lorem.word   => Faker::Lorem.word }
    name         { Faker::Lorem.word }
    requester    { Faker::Lorem.word }
    content      { JSON.generate(items) }
    state        { :pending }
    decision     { :undecided }

    workflow

    trait :with_context do
      after(:create) do |obj|
        obj.update_attributes(:context =>
          {
            "headers"      => {"x-rh-identity" => RequestSpecHelper.encoded_user_hash},
            "original_url" => "http://localhost:3000/api/v1.0/workflows/1/requests"
          }
        )
      end
    end

    trait :with_tenant do
      tenant
    end
  end
end
