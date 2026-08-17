# frozen_string_literal: true

class PictureSelectFieldComponent < ApplicationComponent
  slim_template <<~SLIM
    fieldset
      legend Attach Picture (Optional)
      div
        = label_tag "\#{@form.object_name}_picture_id", "Select Existing Picture"
        = hidden_field_tag "\#{@form.object_name}[picture_id]", picture_id_value, id: "\#{@form.object_name}_picture_id", data: { picture_select_target: "hiddenInput" }
        details.dropdown data-picture-select-target="dropdown" style="margin-bottom: 1rem;"
          summary data-picture-select-target="summary"
            - if selected_picture&.persisted? && selected_picture.file.attached?
              span style="display: flex; align-items: center; gap: 0.75rem;"
                - if (thumb = selected_picture.thumbnail)
                  img src=rails_representation_path(thumb) style="width: 80px; height: 60px; object-fit: cover; border-radius: 3px;" alt=""
                span = picture_label(selected_picture)
            - else
              | Choose an existing picture...
          ul style="max-height: 300px; overflow-y: auto; z-index: 50;"
            li
              a href="#" data-action="click->picture-select#selectOption" data-picture-id="" data-picture-name="Choose an existing picture..." data-preview-url=""
                | None (no picture)
            - pictures.each do |pic|
              - thumb_url = rails_representation_path(pic.thumbnail)
              - label = picture_label(pic)
              li
                a href="#" data-action="click->picture-select#selectOption" data-picture-id=pic.id data-picture-name=label data-preview-url=thumb_url style="display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem;"
                  img src=thumb_url style="width: 60px; height: 45px; object-fit: cover; border-radius: 4px; flex-shrink: 0;" alt=pic.name
                  span style="font-weight: 500;"
                    = label

      details data-picture-select-target="uploadDetails" open=(upload_details_open ? "open" : nil) style="margin-top: 1rem;"
        summary Or Upload New Picture
        div style="margin-top: 0.75rem;"
          = label_tag "\#{@form.object_name}_picture_file", "Picture File"
          = file_field_tag "\#{@form.object_name}[picture_file]", accept: "image/*", id: "\#{@form.object_name}_picture_file", data: { picture_select_target: "fileInput", action: "change->picture-select#updateFilePreview" }
          div style="margin-top: 0.5rem;"
            img data-picture-select-target="filePreview" style="display: none; max-width: 200px; max-height: 150px; object-fit: cover; border-radius: 4px;" alt="Uploaded picture preview"

        div style="margin-top: 0.5rem;"
          = label_tag "\#{@form.object_name}_picture_name", "Picture Name (Optional)"
          = text_field_tag "\#{@form.object_name}[picture_name]", picture_name_value, id: "\#{@form.object_name}_picture_name", placeholder: "Defaults to image file name", data: { picture_select_target: "pictureNameInput" }
  SLIM

  def initialize(form:, team: nil, selected_picture: nil, scope: "current_team")
    @form = form
    @team = team
    @selected_picture = selected_picture
    @scope = scope
  end

  def pictures
    @pictures ||= begin
      relation = @team ? Picture.where(team: @team) : Picture
      relation.with_attached_file.order(created_at: :desc).limit(50)
    end
  end

  def selected_picture
    pic = @selected_picture || begin
      pic_id = @form.object.respond_to?(:picture_id) ? @form.object.picture_id : nil
      if pic_id.present?
        pictures.find do |p|
          p.id == pic_id || p.urlsafe_id == pic_id
        end || Picture.find_by(id: pic_id) || Picture.urlsafe_find(pic_id)
      end
    end
    pic if pic&.persisted?
  end

  def picture_id_value
    if @form.object.respond_to?(:picture_id)
      @form.object.picture_id
    elsif @form.object.respond_to?(:picture) && @form.object.picture.present?
      @form.object.picture.id
    end
  end

  def picture_name_value
    @form.object.respond_to?(:picture_name) ? @form.object.picture_name : nil
  end

  def picture_label(pic)
    if @scope == "admin" && pic.team
      "#{pic.name} (#{pic.team.name})"
    else
      pic.name
    end
  end

  def upload_details_open
    return true if picture_name_value.present?
    return true if @form.object.respond_to?(:picture_file) && @form.object.picture_file.present?

    @form.object.respond_to?(:errors) && @form.object.errors.attribute_names.any? do |k|
      k.to_s.start_with?("picture_file", "picture_name")
    end
  end
end
