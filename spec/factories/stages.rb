# spec/factories/stages.rb
FactoryBot.define do
  factory :stage do
    state { :pending }
    decision { :unknown }

    request
    group
  end
end
