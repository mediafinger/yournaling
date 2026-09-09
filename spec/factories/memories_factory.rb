FactoryBot.define do
  factory :memory do
    team
    weblink
    memo { Faker::Lorem.paragraph(sentence_count: 3, random_sentences_to_add: 3) }
  end
end
