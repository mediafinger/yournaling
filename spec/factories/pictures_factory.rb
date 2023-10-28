FactoryBot.define do
  factory :picture do
    file { Rack::Test::UploadedFile.new("spec/support/macbookair_stickered.jpg", "image/jpeg") }
    name { Faker::Mountain.name }
    team
  end
end
