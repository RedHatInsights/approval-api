# spec/factories/tenants.rb
#
FactoryBot.define do
  factory :tenant do
    sequence(:ref_id, &:to_s)
  end
end
