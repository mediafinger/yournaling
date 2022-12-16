FactoryBot.define do
  factory :team do
    name { Faker::Team.name.titleize }
  end
end
