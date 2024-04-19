class Login < ApplicationRecord
  belongs_to :user, inverse_of: :logins, foreign_key: "user_yid"

  validates :device_id, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true
end
