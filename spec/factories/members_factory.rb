FactoryBot.define do
  factory :member do
    team
    user
    roles { Member::VALID_ROLES.sample(2) }
  end
end
