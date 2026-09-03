# frozen_string_literal: true

# type: Content
#
# A long-form, Markdown-formatted narrative. Like Thought, but for prose:
# the `content` column stores the raw GitHub Flavored Markdown the author typed
# in the Marksmith editor; it is rendered to sanitized HTML on display
# (see MarkdownRenderer). `name` is the headline.
#
# Story can be attached to a Chronicle as a ChronicleEntry, but - unlike the
# other insights - it is not referenced by Memory.
#
class Story < ApplicationRecordForContentAndPosts
  include VisibilityConstrainedByParents

  YID_CODE = "story"

  MIN_CONTENT_LENGTH = 20
  MAX_CONTENT_LENGTH = 16_384

  belongs_to :team, inverse_of: :stories
  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries

  multisearchable(
    against: %i[name content date],
    additional_attributes: ->(story) { { team_id: story.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }
  # Store clean, LF-only Markdown regardless of the browser's line endings.
  normalizes :content, with: ->(content) { content.to_s.gsub("\r\n", "\n").strip }

  validates :name, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { in: MIN_CONTENT_LENGTH..MAX_CONTENT_LENGTH }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  # Rendered, sanitized HTML for the Markdown source. Wrap in `.yui-prose`.
  def content_html
    MarkdownRenderer.render(content)
  end
end
