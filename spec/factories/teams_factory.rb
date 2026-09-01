# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    name { "#{Faker::Superhero.name.pluralize} of #{Faker::Space.star}" }
  end
end
