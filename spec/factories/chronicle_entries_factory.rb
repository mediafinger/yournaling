FactoryBot.define do
  factory :chronicle_entry do
    chronicle
    team { chronicle.team }
    entry { association :thought, team: team }
  end
end
