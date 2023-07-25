class ApplicationRecordYidEnabled < ApplicationRecord
  self.abstract_class = true
  self.primary_key = "yid"

  before_create :set_yid_and_timestamps

  private

  def decode_from_slug(slug)
    # use OpenSSL::Cipher::AES128 or similar to decode to yid
  end

  def encode_to_slug
    # use OpenSSL::Cipher::AES128 or similar to encode yid
  end

  def generate_yid
    "#{self.class::YID_MODEL}_#{now_timestamp}_#{SecureRandom.hex(6)}"
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
