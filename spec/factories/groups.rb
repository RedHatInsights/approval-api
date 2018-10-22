# spec/factories/groups.rb
require 'json'

FactoryBot.define do
  factory :group do
    schema = { :email   => Faker::Internet.email,
               :cc      => Faker::Internet.email,
               :subject => Faker::Lorem.word
             }

    name { Faker::Lorem.word }
    contact_method { Faker::Lorem.word }
    contact_setting { JSON.generate(schema) }

  end
end
