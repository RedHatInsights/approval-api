# spec/factories/stages.rb
FactoryBot.define do
  factory :stage do
    state { :pending }
    decision { :undecided }

    request
    group
  end
end
