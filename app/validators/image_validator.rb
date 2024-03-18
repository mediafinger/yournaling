# NOTE: maybe replace by: https://github.com/igorkasyanchuk/active_storage_validations
# to validate aspect ratio and others
#
# Inspired by: https://github.com/aki77/activestorage-validator/blob/master/lib/activestorage/validator/blob.rb
#
# Example usage (e.g. in the Picture model):
#
# validates :file, presence: true, image: { content_type: :image } # supported options: :image, :audio, :video, :text
# validates :file, presence: true, image: { content_type: %w[image/png image/jpg image/jpeg], size_range: (1..10.megabytes) }
# validates :file, presence: true, image: { content_type: %r{^image/}, size_range: (50.kilobytes..10.megabytes) }
#
class ImageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, values)
    return unless values.attached?

    Array(values).each do |value|
      if options[:size_range].present?
        if options[:size_range].min > value.blob.byte_size
          record.errors.add(
            attribute,
            :min_size_error,
            min_size: ActiveSupport::NumberHelper.number_to_human_size(options[:size_range].min)
          )
        elsif options[:size_range].max < value.blob.byte_size
          record.errors.add(
            attribute,
            :max_size_error,
            max_size: ActiveSupport::NumberHelper.number_to_human_size(options[:size_range].max)
          )
        end
      end

      record.errors.add(attribute, :content_type) unless valid_content_type?(value.blob)
    end
  end

  private

  def valid_content_type?(blob)
    return true if options[:content_type].nil? # no validation

    case options[:content_type]
    when Regexp
      options[:content_type].match?(blob.content_type)
    when Array
      options[:content_type].include?(blob.content_type)
    when Symbol
      blob.public_send(:"#{options[:content_type]}?")
    else
      options[:content_type] == blob.content_type
    end
  end
end
