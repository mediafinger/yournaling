# type: Post
#
class Chronicle < ApplicationRecordForContentAndPosts
  YID_CODE = "cron".freeze

  belongs_to :team, inverse_of: :chronicles, foreign_key: "team_yid"

  has_many :chronicle_locations, inverse_of: :chronicle, foreign_key: "chronicle_yid", dependent: :destroy
  has_many :chronicle_pictures, inverse_of: :chronicle, foreign_key: "chronicle_yid", dependent: :destroy
  has_many :chronicle_weblinks, inverse_of: :chronicle, foreign_key: "chronicle_yid", dependent: :destroy

  has_many :locations, through: :chronicle_locations
  has_many :pictures, through: :chronicle_pictures
  has_many :weblinks, through: :chronicle_weblinks

  multisearchable(
    against: %i[notes], # TODO: too much content for full-text-search?!
    additional_attributes: ->(chronicle) { { team_yid: chronicle.team_yid } }
  )

  attr_readonly :team_yid

  scope :with_includes, -> {
    includes(:team, chronicle_locations: :location, chronicle_pictures: :picture, chronicle_weblinks: :weblink)
  }

  accepts_nested_attributes_for :chronicle_locations, allow_destroy: true
  accepts_nested_attributes_for :chronicle_pictures, allow_destroy: true
  accepts_nested_attributes_for :chronicle_weblinks, allow_destroy: true

  normalizes :note, with: ->(note) { note.strip }

  before_validation :ensure_locations_order_complete
  before_validation :ensure_pictures_order_complete
  before_validation :ensure_weblinks_order_complete

  validates :name, presence: true
  validates :notes, presence: true, length: { minimum: 20, maximum: 5000 } # TODO: more for paying users?
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  private

  def ensure_locations_order_complete
    plucked_yids = chronicle_locations.pluck(:location_yid)
    self.locations_order ||= [] # before persistence it is nil
    added_locs = plucked_yids - locations_order
    removed_locs = locations_order - plucked_yids
    self.locations_order = locations_order - removed_locs + added_locs
  end

  def ensure_pictures_order_complete
    plucked_yids = chronicle_pictures.pluck(:picture_yid)
    self.pictures_order ||= [] # before persistence it is nil
    added_pics = plucked_yids - pictures_order
    removed_pics = pictures_order - plucked_yids
    self.pictures_order = pictures_order - removed_pics + added_pics
  end

  def ensure_weblinks_order_complete
    plucked_yids = chronicle_weblinks.pluck(:weblink_yid)
    self.weblinks_order ||= [] # before persistence it is nil
    added_links = plucked_yids - weblinks_order
    removed_links = weblinks_order - plucked_yids
    self.weblinks_order = weblinks_order - removed_links + added_links
  end
end
