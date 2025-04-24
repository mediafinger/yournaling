# Archivable concern to implement "archive" functionality in a consistent way.
#
# AR table of models including this concern must have a `archived_at` datetime column.
# AR table of models including this concern should have a `where: "(archived_at IS NULL)"` index on the table.
#
#   include Archivable
#   self.archived_retention_period = 30.days # if none is set, archived records will never be archived
#
# The concern will add the following functionality:
#
#  * a `default_scope` that filters out archived records
#  * a `with_archived` scope that returns all records
#  * a `only_archived` scope that returns only archived records
#  * a `archived?` method that returns true if the record has been archived
#  * a `present?` method that returns false for archived records
#  * a `archive` method that sets the `archived_at` column to the current time
#  * a `archive_associated` method that triggers archive for all associated records (untested)
#  * a `archive_associated!` method that triggers archive_associated but raises if nothing is done (untested)
#  * a `archive_all` method that triggers archive for all records of a relation
#  * a `archive_associated_all` method that triggers archive_associated for all records of a relation (untested)
#  * a `before_validation` hook is added to `make_changes_invalid_on_archived_records``
#
# Once we include this concern in a model with associated records, we have to decide, how to handle associated records:
#  * option 1: try to archive associated records - raise error if they don't have the archived_at column
#  * option 2: try to archive associated records - delete them properly if they don't have the archived_at column
#  * option 3: configure it for every model individually
#
# DANGER ZONE: `.delete` and `.destroy` will still work as for all other AR models and really delete the records.
#
# The job Recurring::CleanupArchivedRecordsJob should run every night,
#   detect all models that include the Archivable concern
#   and calls the `cleanup_archived_records` method on each of them.
#   The method really deletes archived records, but only when they are older than the retention period.
#   When self.archived_retention_period is not set, the archived records will never be really archived.
#
# NOTE
# Missing are specs for the `archive_associated_associated_records` functionality
#   as the Session model does not have any has_many associations.
#   Those specs MUST be added as soon as we start using the Archivable concern in other models.
#
module Archivable
  extend ActiveSupport::Concern

  included do
    define_callbacks :archive_associated

    default_scope { where(archived_at: nil) }

    scope :only_archived, -> { with_archived.where.not(archived_at: nil) }
    scope :with_archived, -> { unscope(where: :archived_at) }

    before_validation :make_changes_invalid_on_archived_records
  end

  class_methods do
    def archive_all
      update_all(archived_at: Time.current) if has_attribute? :archived_at # rubocop:disable Rails/SkipsModelValidations
    end

    def archive_associated_all
      find_each(&:archive_associated)
    end

    def archive_associated_all!
      find_each do |record|
        record.archive_associated || raise(ActiveRecord::RecordNotDestroyed.new("Failed to destroy the record", record))
      end
    end

    def archived_retention_period=(period)
      @archived_retention_period = period
    end

    def archived_retention_period
      @archived_retention_period
    end

    def cleanup_archived_records
      if archived_retention_period.nil?
        Rails.logger.info do
          "#{self.class.name} has no archived_retention_period set, cleanup_archived_records will not run"
        end
        return
      end

      Rails.logger.info do
        "#{self.class.name} cleanup_archived_records archived_before: #{Time.current - archived_retention_period}"
      end

      only_archived.where.not(archived_at: (Time.current - archived_retention_period)..).destroy_all
    end
  end

  def archived?
    archived_at.present?
  end

  def present?
    !archived? && super
  end

  def make_changes_invalid_on_archived_records
    errors.add(:base, "archived records must not be changed") if archived? && changed?
  end

  def archive
    update_column :archived_at, Time.current if has_attribute? :archived_at # rubocop:disable Rails/SkipsModelValidations
  end

  def archive_associated
    callbacks_result =
      transaction do
        run_callbacks :archive_associated do
          archive_associated_associated_records
          archive
        end
      end

    callbacks_result ? self : false
  end

  def archive_associated!
    archive_associated || raise(ActiveRecord::RecordNotDestroyed.new("Failed to destroy the record", self))
  end

  # NOTE: untested functionality! (as we do not have any has_many associations yet)
  #
  def archive_associated_associated_records
    associations = self.class.reflect_on_all_associations.select do |reflection|
      reflection.options[:dependent].present?
    end

    associations.each do |association|
      associated_records = public_send(association.name)

      if association.options[:dependent] == :destroy
        associated_records.archive_associated_all
      elsif association.options[:dependent] == :delete_all
        associated_records.archive_all
      end
    end
  end
end
