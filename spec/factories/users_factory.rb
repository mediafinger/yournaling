# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.unique.name }
    email { Faker::Internet.unique.email(domain: "example.com") }
    password { :foobar1234 } # bcrypt will hash this

    # A freshly registered user is unverified, so that is the default the factory mirrors.
    trait :email_verified do
      email_verified_at { Time.current }
    end

    trait :admin do
      role { "admin" }
    end
  end
end
