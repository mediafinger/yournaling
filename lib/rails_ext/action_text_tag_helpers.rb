module ActionText
  module TagHelper
    def markdown_area(record, name, value: nil, **options)
      field_name = "#{record.class.model_name.param_key}[#{name}]"
      value = record.safe_markdown_attribute(name).content.to_s if value.nil?

      data = options.delete(:data) || {}
      data.reverse_merge! \
        uploads_url: action_text_markdown_uploads_url(record_gid: record.to_signed_global_id.to_s, attribute_name: name,
          format: "json")

      tag.house_md value, name: field_name, data: data, **options
    end

    def house_toolbar(**, &)
      tag.house_md_toolbar(**, &)
    end

    def house_toolbar_button(action, **, &)
      tag.button(title: action.to_s.humanize, data: { "house-md-action": action }, **, &)
    end

    def house_toolbar_file_upload_button(name: "upload", title: "Upload File", **options, &block)
      tag.label title: title, **options do
        safe_join [
          file_field_tag(name, data: { "house-md-toolbar-file-picker": true }, style: "display: none;"),
          capture(&block),
        ]
      end
    end
  end
end

module ActionView::Helpers
  class FormBuilder
    def markdown_area(method, **)
      @template.markdown_area(@object, method, **)
    end
  end
end
