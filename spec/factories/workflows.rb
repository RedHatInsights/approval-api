# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    name { Faker::Name.unique.name }
    template

    trait :with_tenant do
      tenant
    end
  end
end
