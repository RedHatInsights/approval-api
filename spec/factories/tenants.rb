# spec/factories/tenants.rb
#
FactoryBot.define do
  factory :tenant do
    sequence(:external_tenant, &:to_s)
  end
end
