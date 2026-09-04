# frozen_string_literal: true

# Shared by ManageHeaderComponent (Member — visibility still lives in its
# header) and RecordFooterComponent (Chronicle / Memory / Insight cards —
# visibility now lives in the footer's center): render the visibility
# control — the primary button that opens ContentVisibilityModalComponent
# when the viewer may change it, a static badge otherwise.
#
# Including class must expose `@record`, `current_user` and `allowed_to?`
# (all ApplicationComponent subclasses do).
module VisibilityControl
  VISIBILITY_BADGE_VARIANTS = {
    "draft" => :neutral,
    "internal" => :info,
    "published" => :success,
    "archived" => :warning,
    "blocked" => :danger,
  }.freeze

  def show_visibility?
    @record.respond_to?(:visibility) && @record.visibility.present?
  end

  def can_change_visibility?
    return false unless show_visibility?
    return false unless current_user.present?

    allowed_to?(:update?, @record, with: ContentVisibilityPolicy)
  end

  def visibility_label
    @record.visibility.to_s.capitalize
  end

  def visibility_badge_variant
    VISIBILITY_BADGE_VARIANTS.fetch(@record.visibility.to_s, :neutral)
  end
end
