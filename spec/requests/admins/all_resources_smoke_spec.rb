# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin resources smoke", type: :request do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:team) { FactoryBot.create(:team) }

  before { sign_in(admin_user) }

  it "renders index/new for chronicles, members, memories, stories, thoughts, weblinks, pictures, locations",
    aggregate_failures: true do
    FactoryBot.create(:chronicle, team: team)
    FactoryBot.create(:location, team: team)
    FactoryBot.create(:member, team: team)
    FactoryBot.create(:memory, team: team)
    FactoryBot.create(:picture, team: team)
    FactoryBot.create(:story, team: team)
    FactoryBot.create(:thought, team: team)
    FactoryBot.create(:weblink, team: team)

    %w[chronicles members memories stories thoughts weblinks pictures locations].each do |res|
      get "/admin/#{res}"
      expect(response).to have_http_status(:ok), "index #{res} => #{response.status}"
      get "/admin/#{res}/new"
      expect(response).to have_http_status(:ok), "new #{res} => #{response.status}"
    end
  end

  it "renders show/edit for each resource", aggregate_failures: true do
    records = {
      "chronicles" => FactoryBot.create(:chronicle, team: team),
      "locations" => FactoryBot.create(:location, team: team),
      "members" => FactoryBot.create(:member, team: team),
      "memories" => FactoryBot.create(:memory, team: team),
      "pictures" => FactoryBot.create(:picture, team: team),
      "stories" => FactoryBot.create(:story, team: team),
      "thoughts" => FactoryBot.create(:thought, team: team),
      "weblinks" => FactoryBot.create(:weblink, team: team),
    }
    records.each do |res, record|
      get "/admin/#{res}/#{record.to_param}"
      expect(response).to have_http_status(:ok), "show #{res} => #{response.status}"
      get "/admin/#{res}/#{record.to_param}/edit"
      expect(response).to have_http_status(:ok), "edit #{res} => #{response.status}"
    end
  end
end
