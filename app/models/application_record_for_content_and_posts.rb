class ApplicationRecordForContentAndPosts < ApplicationRecordYidEnabled
  self.abstract_class = true

  VISIBILITY_STATES = %w[draft internal published archived blocked].freeze
  VISIBILITY_PERMISSIVENESS = {
    "blocked" => 0,
    "archived" => 1,
    "draft" => 2,
    "internal" => 3,
    "published" => 4,
  }.freeze

  YID_CODE = "abstract_class_must_not_be_used".freeze

  after_initialize :define_visibility_methods

  def visibility_level(val = visibility)
    VISIBILITY_PERMISSIVENESS.fetch(val.to_s, 0)
  end

  def more_permissive_than?(other_visibility)
    visibility_level > visibility_level(other_visibility)
  end

  def less_permissive_than?(other_visibility)
    visibility_level < visibility_level(other_visibility)
  end

  private

  # NOTE: defines methods draft? internal? published? archived? blocked?
  # on the descendant classes
  def define_visibility_methods
    return unless self.class.column_names.include?("visibility")

    VISIBILITY_STATES.each do |vs|
      self.class.send(:define_method, :"#{vs}?") do
        visibility.to_s == vs.to_s
      end
    end
  end
end

__END__

## Visibility of content

* draft
  * visible to: team member with owner, manager, editor or publisher role and the creator themselves
  * default state for all new content
* internal
  * now also visible to team members with the reader role
  * this should clearly be a paid feature
* published
  * visible to everyone on the platform
  * visible to everyone in the whole wide world
* archived
  * like draft, but not listed with them, but in an extra section
* blocked
  * when content violates the rules, a platform-moderator can block the content
  * it will be treated like archieved, but visiblity can not be changed by team anymore
  * only after a change and a review a platform-moderator can unblock the content again
  * maybe automatic blocking after multiple user-reports
* only team members with the publisher role can publish content to people outside their team
* owners, managers and publishers can unpublish content
