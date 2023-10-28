FactoryBot.define do
  factory :picture do
    creator { create(:user) }
    file { Rack::Test::UploadedFile.new("spec/support/macbookair_stickered.jpg", "image/jpeg") }
    name { Faker::Mountain.name }
    team

    trait :with_updater do
      updater { create(:user) }
    end
  end
end
