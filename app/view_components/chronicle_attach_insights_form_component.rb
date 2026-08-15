# frozen_string_literal: true

class ChronicleAttachInsightsFormComponent < ApplicationComponent
  slim_template <<~SLIM
    fieldset
      legend Attach Picture (Optional)
      div
        = @form.label :picture_id, "Select Existing Picture"
        = @form.hidden_field :picture_id, data: { picture_select_target: "hiddenInput" }
        details.dropdown data-picture-select-target="dropdown" style="margin-bottom: 1rem;"
          summary data-picture-select-target="summary"
            - if selected_picture
              span style="display: flex; align-items: center; gap: 0.75rem;"
                img src=rails_representation_path(selected_picture.thumbnail) style="width: 40px; height: 30px; object-fit: cover; border-radius: 3px;" alt=""
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

      div style="margin-top: 1rem;"
        = @form.label :picture_file, "Or Upload New Picture"
        = @form.file_field :picture_file, accept: "image/*", data: { picture_select_target: "fileInput", action: "change->picture-select#updateFilePreview" }
        div style="margin-top: 0.5rem;"
          img data-picture-select-target="filePreview" style="display: none; max-width: 200px; max-height: 150px; object-fit: cover; border-radius: 4px;" alt="Uploaded picture preview"

      div
        = @form.label :picture_name, "New Picture Name (Optional)"
        = @form.text_field :picture_name, placeholder: "Defaults to image file name"

    fieldset
      legend Attach Location (Optional)
      div
        = @form.label :location_id, "Select Existing Location"
        = @form.select :location_id, location_options, selected: @form.object.location_id, include_blank: "Choose an existing location..."
      div style="margin-top: 1rem;"
        h6 Or Create New Location
        div
          = @form.label :location_name, "Location Name"
          = @form.text_field :location_name, placeholder: "e.g. Cabo de Gata Camping"
        div
          = @form.label :location_address, "Address"
          = @form.text_field :location_address, placeholder: "e.g. Playa de los Genoveses, San Jose"
        div
          = @form.label :location_url, "Map / Website URL"
          = @form.url_field :location_url, placeholder: "e.g. https://maps.google.com/..."

    fieldset
      legend Attach Thought (Optional)
      div
        = @form.label :thought_id, "Select Existing Thought"
        = @form.select :thought_id, thought_options, selected: @form.object.thought_id, include_blank: "Choose an existing thought..."
      div style="margin-top: 1rem;"
        h6 Or Create New Thought
        div
          = @form.label :thought_text, "Thought Text"
          = @form.text_area :thought_text, rows: 3, placeholder: "Write a memorable thought or reflection..."

    fieldset
      legend Attach Weblink (Optional)
      div
        = @form.label :weblink_id, "Select Existing Weblink"
        = @form.select :weblink_id, weblink_options, selected: @form.object.weblink_id, include_blank: "Choose an existing weblink..."
      div style="margin-top: 1rem;"
        h6 Or Create New Weblink
        div
          = @form.label :weblink_name, "Link Name"
          = @form.text_field :weblink_name, placeholder: "e.g. Route Planning Guide"
        div
          = @form.label :weblink_url, "URL"
          = @form.url_field :weblink_url, placeholder: "e.g. https://route-planner.example.com"
        div
          = @form.label :weblink_description, "Description (Optional)"
          = @form.text_field :weblink_description, placeholder: "Brief notes about the link"
  SLIM

  def initialize(form:, chronicle:, scope: "current_team", team_pictures: nil, team_locations: nil, team_thoughts: nil,
                 team_weblinks: nil)
    @form = form
    @chronicle = chronicle
    @scope = scope
    @team_pictures = team_pictures
    @team_locations = team_locations
    @team_thoughts = team_thoughts
    @team_weblinks = team_weblinks
  end

  def pictures
    @pictures ||= @team_pictures || begin
      scope_team = @scope == "admin" ? @chronicle.team : current_team
      if scope_team
        Picture.where(team: scope_team).with_attached_file.order(created_at: :desc)
      else
        Picture.with_attached_file.order(created_at: :desc)
      end
    end
  end

  def selected_picture
    pictures.find { |p| p.id == @form.object.picture_id || p.urlsafe_id == @form.object.picture_id }
  end

  def picture_label(pic)
    if @scope == "admin" && pic.team
      "#{pic.name} (#{pic.team.name})"
    else
      pic.name
    end
  end

  def locations
    @locations ||= @team_locations || begin
      scope_team = @scope == "admin" ? @chronicle.team : current_team
      scope_team ? Location.where(team: scope_team).order(created_at: :desc) : Location.order(created_at: :desc)
    end
  end

  def location_options
    locations.map do |l|
      label = @scope == "admin" && l.team ? "#{l.name} (#{l.team.name})" : l.name
      [label, l.id]
    end
  end

  def thoughts
    @thoughts ||= @team_thoughts || begin
      scope_team = @scope == "admin" ? @chronicle.team : current_team
      scope_team ? Thought.where(team: scope_team).order(created_at: :desc) : Thought.order(created_at: :desc)
    end
  end

  def thought_options
    thoughts.map do |t|
      label = @scope == "admin" && t.team ? "#{t.text.truncate(50)} (#{t.team.name})" : t.text.truncate(60)
      [label, t.id]
    end
  end

  def weblinks
    @weblinks ||= @team_weblinks || begin
      scope_team = @scope == "admin" ? @chronicle.team : current_team
      scope_team ? Weblink.where(team: scope_team).order(created_at: :desc) : Weblink.order(created_at: :desc)
    end
  end

  def weblink_options
    weblinks.map do |w|
      label = @scope == "admin" && w.team ? "#{w.name} (#{w.team.name})" : w.name
      [label, w.id]
    end
  end
end
