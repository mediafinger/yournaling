FactoryBot.define do
  factory :thought do
    text { Faker::Quote.matz.truncate(1024) }
    date { Date.current }
    team
  end
end
