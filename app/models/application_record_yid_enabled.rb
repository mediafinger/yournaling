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
      # An unknown prefix means no model claims this id, which is a miss, not a NoMethodError.
      id_code_models[id.to_s.split("_").first]&.find_by(id:)
    end

    def create_with_event(record:, event_params: {})
      transaction do
        # archspec:disable-next-line dependencies.no_cycles -- we are aware and ok with it
        record.save && RecordEventService.call(record:, name: :created, **event_params)
      end
    end

    def update_with_event(record:, event_params: {})
      transaction do
        # archspec:disable-next-line dependencies.no_cycles -- we are aware and ok with it
        record.save && RecordEventService.call(record:, name: :updated, **event_params)
      end
    end

    def destroy_with_event(record:, event_params: {})
      transaction do
        # archspec:disable-next-line dependencies.no_cycles -- we are aware and ok with it
        RecordEventService.call(record:, name: :deleted, **event_params)
        record.destroy! # TODO: refactor controller actions to not raise
      end
    end

    def urlsafe_fynd(urlsafe_id)
      decoded_id = decode_urlsafe_id(urlsafe_id)

      decoded_id && fynd(decoded_id)
    end

    def urlsafe_find(urlsafe_id)
      decoded_id = decode_urlsafe_id(urlsafe_id)

      decoded_id && find_by(id: decoded_id)
    end

    def urlsafe_find!(urlsafe_id)
      decoded_id = decode_urlsafe_id(urlsafe_id)

      raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} with [urlsafe_id=#{urlsafe_id}]") if decoded_id.nil?

      find(decoded_id)
    end

    # The single gate between an attacker-controlled URL segment and the database. Base64 decoding
    # accepts far more than the ids this app issues: "new" and "edit" decode to arbitrary bytes,
    # "12345" is not valid Base64 at all. Neither can denote a record, so both must read as a miss
    # here -- handing them on raises PG::CharacterNotInRepertoire (invalid UTF-8 in a query) or
    # NoMethodError, and ErrorHandler can only report those as a 500 where a 404 is the truth.
    def decode_urlsafe_id(urlsafe_id)
      decoded_id = Base64.urlsafe_decode64(urlsafe_id.to_s)

      decoded_id if decoded_id.force_encoding(Encoding::UTF_8).valid_encoding?
    rescue ArgumentError
      nil
    end

    # rubocop:disable Style/ClassVars
    def id_code_models
      @@id_code_models ||= id_enabled_models.to_h do |model|
        [model::YID_CODE, model.name.constantize]
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
