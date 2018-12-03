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
  end
end
