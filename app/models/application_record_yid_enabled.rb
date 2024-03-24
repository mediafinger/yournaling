class ApplicationRecordYidEnabled < ApplicationRecord
  include PgSearch::Model

  self.abstract_class = true
  self.primary_key = "yid"

  # NOTE: setting a default order by created_at DESC for all YID enabled models
  # should be the same as ordering by YID (with the newest models on top)
  # but faster. In case any other ordering is needed use `Model.reorder(...)`.
  # Be aware that `find_in_batches` ignores any default order.
  #
  default_scope { order(created_at: :desc) }

  before_create :set_yid_and_timestamps

  class << self
    def fynd(yid)
      yid_code_models[yid.split("_").first].find_by(yid:)
    end

    def urlsafe_find(urlsafe_id)
      find_by(yid: Base64.urlsafe_decode64(urlsafe_id))
    end

    def urlsafe_find!(urlsafe_id)
      find_by!(yid: Base64.urlsafe_decode64(urlsafe_id))
    end

    # rubocop:disable Style/ClassVars
    def yid_code_models
      @@yid_code_models ||= yid_enabled_models.each_with_object({}) do |model, hash|
        hash[model::YID_CODE] = model.name.constantize
      end
    end

    def yid_enabled_models
      # here be dragons
      Rails.application.eager_load! unless defined?(@@descendants)
      @@descendants ||= ApplicationRecordYidEnabled.descendants
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

  # or use OpenSSL::Cipher::AES128 or similar to encode from / decode to yid
  def urlsafe_id
    Base64.urlsafe_encode64(yid, padding: false)
  end

  def to_yid(urlsafe_id)
    Base64.urlsafe_decode64(urlsafe_id)
  end

  private

  def generate_yid
    "#{self.class::YID_CODE}_#{now_timestamp}_#{SecureRandom.hex(6)}"
  end

  def now_timestamp
    @now_timestamp ||= Time.current.utc.iso8601(6)
  end

  def set_yid_and_timestamps
    self.created_at = now_timestamp
    self.updated_at = now_timestamp
    self.yid = generate_yid
  end
end
