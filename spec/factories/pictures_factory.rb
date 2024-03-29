FactoryBot.define do
  factory :picture do
    file { Rack::Test::UploadedFile.new("spec/support/macbookair_stickered.jpg", "image/jpeg") }
    name { Faker::Mountain.unique.name }
    team
  end
end
