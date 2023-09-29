FactoryBot.define do
  factory :location do
    address { Faker::Address.full_address }
    country_code { EnglishCountriesForSelectService.call.keys.sample }
    lat { rand(-90.0..90.0).round(6) }
    long { rand(-180.0..180.0).round(6) }
    name { Faker::Restaurant.name }
    link { Faker::Internet.url(host: "example.com") }
  end
end
