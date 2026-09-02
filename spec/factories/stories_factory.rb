# frozen_string_literal: true

FactoryBot.define do
  factory :story do
    name { Faker::Book.title }
    content { "## #{Faker::Lorem.sentence}\n\n#{Faker::Lorem.paragraphs(number: 3).join("\n\n")}" }
    date { Date.current }
    team
  end
end
