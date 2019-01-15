# spec/factories/groups.rb
require 'json'

FactoryBot.define do
  factory :group do
    name { Faker::Lorem.word }
  end
end
