class Weblink < ApplicationRecordYidEnabled
  YID_CODE = "link".freeze

  belongs_to :team, inverse_of: :weblinks, foreign_key: "team_yid"

  has_many :memories, class_name: "Memory", foreign_key: "weblink_yid", primary_key: "yid", inverse_of: :weblink,
    dependent: :nullify

  multisearchable(
    against: %i[name],
    additional_attributes: ->(weblink) { { team_yid: weblink.team_yid } }
  )

  attr_readonly :team_yid

  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) { ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") }

  validates :name, presence: true
  validates :team_yid, presence: true, uniqueness: { scope: :url }
  validates :url, presence: true, uniqueness: { scope: :team_yid }
end
