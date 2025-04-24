module Recurring
  class CleanupArchivedRecordsJob < ApplicationJob
    queue_as :default

    def perform
      # detect all models that include the Archivable concern (does not work in development without eager loading)
      klasses = ObjectSpace.each_object(Class).select { |c| c.included_modules.include? Archivable }

      klasses.each do |klass|
        klass.to_s.camelcase.constantize.cleanup_archived_records
      end
    end
  end
end
