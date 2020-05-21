# spec/factories/requests.rb
FactoryBot.define do
  factory :request do
    items = {:product   => Faker::Lorem.word,
             :portfolio => Faker::Lorem.word,
             :order_id  => Faker::Lorem.word,
             :platform  => Faker::Lorem.word,
             :params    => {
               Faker::Lorem.word => Faker::Lorem.word,
               Faker::Lorem.word => Faker::Lorem.word,
               Faker::Lorem.word => Faker::Lorem.word
             }}
    name            { Faker::Lorem.word }
    requester_name  { Faker::Lorem.word }
    owner           { Faker::Lorem.word }
    group_name      { Faker::Lorem.word }
    request_context { RequestContext.new(:content => items) }
    state           { :pending }
    decision        { :undecided }

    workflow

    trait :with_context do
      after(:create) do |obj|
        obj.request_context.update(:context => RequestSpecHelper.default_request_hash)
      end
    end

    trait :with_tenant do
      tenant
    end
  end
end
