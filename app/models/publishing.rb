# frozen_string_literal: true

class Publishing < ApplicationRecordForContentAndPosts
  YID_CODE = "pub"

  belongs_to :team
  belongs_to :post, polymorphic: true, foreign_type: :post_type

  validates :first_published_at, :republished_at, :published_count, :visibility, presence: true
  validates :post_id, uniqueness: { scope: :post_type }

  scope :published, -> { where(visibility: "published") }
  scope :feed, -> { published.reorder(republished_at: :desc).limit(5) }
end
