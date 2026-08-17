# frozen_string_literal: true

FactoryBot.define do
  factory :publishing do
    team
    post factory: %i[chronicle]
    first_published_at { Time.current }
    republished_at { Time.current }
    published_count { 1 }
    visibility { "published" }
  end
end
