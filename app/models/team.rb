class Team < ApplicationRecord
  has_many :members, class_name: "Member", inverse_of: :team, dependent: :destroy
  has_many :users, through: :members
end
