FactoryBot.define do
  factory :picture do
    name { Faker::Mountain.name }

    trait :with_image do
      # file { fixture_file_upload(Rails.root.join("spec/support", "macbookair_stickered.jpg"), "image/jpeg") }
      file { Rack::Test::UploadedFile.new("spec/support/macbookair_stickered.jpg", "image/jpeg") }
    end
  end
end
