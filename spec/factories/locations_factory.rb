FactoryBot.define do
  factory :location do
    name { Faker::Mountain.unique.name }
    lat { rand(-90.0...90.0).round(10) }
    long { rand(-180.0...180.0).round(10) }
    address { {} }
    team

    after(:build) do |location, _params|
      location.url = "https://www.google.de/maps/place/#{location.lat},#{location.long}"
    end
  end
end
