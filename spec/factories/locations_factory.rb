FactoryBot.define do
  factory :location do
    name { Faker::Mountain.unique.name }
    country_code { CountriesEnForSelectService.call.keys.sample }
    address { Faker::Address.full_address }
    lat { rand(-90.0...90.0).round(10) }
    long { rand(-180.0...180.0).round(10) }
    team
  end
end
