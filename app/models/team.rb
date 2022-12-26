class Team < ApplicationRecord
  has_many :members, class_name: "Member", inverse_of: :team, dependent: :destroy
  has_many :users, through: :members

  validates :name, presence: true, uniqueness: true, length: { maximum: 72 }
end
