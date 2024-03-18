class Weblink < ApplicationRecordYidEnabled
  YID_CODE = "link".freeze

  belongs_to :team, inverse_of: :weblinks, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) { ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") }

  validates :name, presence: true
  validates :team_yid, presence: true, uniqueness: { scope: :url }
  validates :url, presence: true, uniqueness: { scope: :team_yid }
end
