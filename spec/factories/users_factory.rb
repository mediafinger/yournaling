FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email(domain: "example.com") }
    password { Faker::Internet.password(min_length: 10, max_length: 72) } # bcrypt will hash this
  end
end
