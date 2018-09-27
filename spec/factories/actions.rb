# spec/factories/actions.rb
FactoryBot.define do
  factory :action do
    processed_by { Faker::Lorem.word }
    decision { :unknown }

    stage
  end
end
