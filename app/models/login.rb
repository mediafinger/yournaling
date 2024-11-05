class Login < ApplicationRecord
  belongs_to :user, inverse_of: :logins

  before_validation :generate_device_id, on: :create

  validates :device_id, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true

  private

  def generate_device_id
    return if device_id.present?

    self.device_id = Digest::SHA256.hexdigest("#{ip_address} #{user_agent}")
  end
end
