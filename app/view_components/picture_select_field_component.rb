# frozen_string_literal: true

class PictureSelectFieldComponent < ApplicationComponent
  # NOTE: as of the Warm Editorial migration this component is not rendered by
  # any view — InsightAttachmentManagerComponent covers picture attachment.
  # Kept (and sidecar-templated) per TODO_UI_DESIGN.md; a candidate for removal.
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
