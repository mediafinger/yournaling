FactoryBot.define do
  factory :thought do
    text { Faker::Quote.matz.truncate(500) }
    date { Date.current }
    team
  end
end
