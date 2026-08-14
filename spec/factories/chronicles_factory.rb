# frozen_string_literal: true

FactoryBot.define do
  factory :chronicle do
    name { Faker::Lorem.unique.words(number: 3).join(" ").titleize }
    notice { Faker::Lorem.paragraph(sentence_count: 5, random_sentences_to_add: 5) }
    start_date { Date.current }
    team
  end
end
