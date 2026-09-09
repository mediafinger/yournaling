FactoryBot.define do
  factory :weblink do
    # description { "MyText" }
    name { Faker::Fantasy::Tolkien.unique.location }
    # preview_snippet { {} }
    url { "https://example.com/#{Faker::Marketing.buzzwords.parameterize}" }
    team
  end
end
