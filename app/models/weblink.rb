# type: Content
#
class Weblink < ApplicationRecordForContentAndPosts
  YID_CODE = "link".freeze

  belongs_to :team, inverse_of: :weblinks

  has_many :memories, class_name: "Memory", inverse_of: :weblink,
    dependent: :nullify

  multisearchable(
    against: %i[name],
    additional_attributes: ->(weblink) { { team_id: weblink.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) { ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") }

  validates :name, presence: true
  validates :team_id, uniqueness: { scope: :url }
  validates :url, presence: true, uniqueness: { scope: :team_id }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
