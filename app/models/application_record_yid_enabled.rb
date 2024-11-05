class ApplicationRecordYidEnabled < ApplicationRecord
  include PgSearch::Model

  self.abstract_class = true

  # NOTE: setting a default order by created_at DESC for all YID enabled models
  # should be the same as ordering by YID (with the newest models on top)
  # but faster. In case any other ordering is needed use `Model.reorder(...)`.
  # Be aware that `find_in_batches` ignores any default order.
  #
  default_scope { order(created_at: :desc) }

  before_create :set_id_and_timestamps

  class << self
    def fynd(id)
      id_code_models[id.split("_").first].find_by(id:)
    end

    def create_with_history(record:, history_params: {})
      transaction do
        record.save && RecordHistoryService.call(record:, event: :created, **history_params)
      end
    end

    def update_with_history(record:, history_params: {})
      transaction do
        record.save && RecordHistoryService.call(record:, event: :updated, **history_params)
      end
    end

    def destroy_with_history(record:, history_params: {})
      transaction do
        RecordHistoryService.call(record:, event: :deleted, **history_params)
        record.destroy! # TODO: refactor controller actions to not raise
      end
    end

    def urlsafe_fynd(urlsafe_id)
      fynd(Base64.urlsafe_decode64(urlsafe_id))
    end

    def urlsafe_find(urlsafe_id)
      find_by(id: Base64.urlsafe_decode64(urlsafe_id))
    end

    def urlsafe_find!(urlsafe_id)
      find(Base64.urlsafe_decode64(urlsafe_id))
    end

    # rubocop:disable Style/ClassVars
    def id_code_models
      @@id_code_models ||= id_enabled_models.each_with_object({}) do |model, hash|
        hash[model::YID_CODE] = model.name.constantize
      end
    end

    def id_enabled_models
      # here be dragons
      Rails.application.eager_load! unless defined?(@@descendants)
      @@descendants ||= ApplicationRecordYidEnabled.descendants.reject do |klass|
        klass.name == "ApplicationRecordForContentAndPosts"
      end
    end
    # rubocop:enable Style/ClassVars
  end

  # NOTE: overwriting ActiveRecord functionality!!
  # to have our urlsafe / Base64 encoded YID in the URLs, instead of the plain-text YID
  #
  def to_param
    return nil unless persisted?

    urlsafe_id
  end

  # or use OpenSSL::Cipher::AES128 or similar to encode from / decode to id
  def urlsafe_id
    Base64.urlsafe_encode64(id, padding: false)
  end

  private

  def generate_id
    "#{self.class::YID_CODE}_#{now_timestamp}_#{SecureRandom.hex(6)}"
  end

  def now_timestamp
    @now_timestamp ||= Time.current.utc.iso8601(6)
  end

  def set_id_and_timestamps
    self.created_at = now_timestamp
    self.updated_at = now_timestamp
    self.id = generate_id
  end
end
