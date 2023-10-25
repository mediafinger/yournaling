FactoryBot.define do
  factory :user do
    name { Faker::Name.unique.name }
    email { Faker::Internet.unique.email(domain: "example.com") }
    password { :foobar1234 } # bcrypt will hash this
  end
end
