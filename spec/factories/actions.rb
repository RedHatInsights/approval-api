# spec/factories/actions.rb
FactoryBot.define do
  factory :action do
    processed_by { Faker::Lorem.word }
    operation { :memo }

    stage
  end
end
