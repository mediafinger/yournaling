# frozen_string_literal: true

class MemoryAttachInsightsFormComponent < ApplicationComponent
  slim_template <<~SLIM
    = render PictureSelectFieldComponent.new(form: @form, team: team, selected_picture: selected_picture)

    fieldset data-controller="insight-select"
      legend Attach Location (Optional)
      div
        = label_tag "\#{@form.object_name}_location_id", "Select Existing Location"
        = select_tag "\#{@form.object_name}[location_id]", options_for_select(location_options, selected_location_id), include_blank: "Choose an existing location...", id: "\#{@form.object_name}_location_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" style="margin-top: 1rem;"
        summary Or Create New Location
        div style="margin-top: 0.75rem;"
          div
            = label_tag "\#{@form.object_name}_location_name", "Location Name"
            = text_field_tag "\#{@form.object_name}[location_name]", nil, id: "\#{@form.object_name}_location_name", placeholder: "e.g. Cabo de Gata Camping", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_location_address", "Address"
            = text_field_tag "\#{@form.object_name}[location_address]", nil, id: "\#{@form.object_name}_location_address", placeholder: "e.g. Playa de los Genoveses, San Jose", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_location_url", "Map / Website URL"
            = url_field_tag "\#{@form.object_name}[location_url]", nil, id: "\#{@form.object_name}_location_url", placeholder: "e.g. https://maps.google.com/...", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }

    fieldset data-controller="insight-select"
      legend Attach Thought (Optional)
      div
        = label_tag "\#{@form.object_name}_thought_id", "Select Existing Thought"
        = select_tag "\#{@form.object_name}[thought_id]", options_for_select(thought_options, selected_thought_id), include_blank: "Choose an existing thought...", id: "\#{@form.object_name}_thought_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" style="margin-top: 1rem;"
        summary Or Create New Thought
        div style="margin-top: 0.75rem;"
          = label_tag "\#{@form.object_name}_thought_text", "Thought Text"
          = text_area_tag "\#{@form.object_name}[thought_text]", nil, id: "\#{@form.object_name}_thought_text", rows: 3, placeholder: "Write a memorable thought or reflection...", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }

    fieldset data-controller="insight-select"
      legend Attach Weblink (Optional)
      div
        = label_tag "\#{@form.object_name}_weblink_id", "Select Existing Weblink"
        = select_tag "\#{@form.object_name}[weblink_id]", options_for_select(weblink_options, selected_weblink_id), include_blank: "Choose an existing weblink...", id: "\#{@form.object_name}_weblink_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" style="margin-top: 1rem;"
        summary Or Create New Weblink
        div style="margin-top: 0.75rem;"
          div
            = label_tag "\#{@form.object_name}_weblink_name", "Link Name"
            = text_field_tag "\#{@form.object_name}[weblink_name]", nil, id: "\#{@form.object_name}_weblink_name", placeholder: "e.g. Route Planning Guide", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_weblink_url", "URL"
            = url_field_tag "\#{@form.object_name}[weblink_url]", nil, id: "\#{@form.object_name}_weblink_url", placeholder: "e.g. https://route-planner.example.com", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_weblink_description", "Description (Optional)"
            = text_field_tag "\#{@form.object_name}[weblink_description]", nil, id: "\#{@form.object_name}_weblink_description", placeholder: "Brief notes about the link", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
  SLIM

  def initialize(form:, memory:)
    @form = form
    @memory = memory
  end

  def team
    @memory.team || current_team
  end

  def selected_picture
    @memory.picture
  end

  def selected_location_id
    @memory.location_id
  end

  def selected_thought_id
    @memory.thought_id
  end

  def selected_weblink_id
    @memory.weblink_id
  end

  def locations
    @locations ||= begin
      relation = team ? Location.where(team: team) : Location
      relation.order(created_at: :desc).limit(50)
    end
  end

  def location_options
    locations.map { |l| [l.name, l.id] }
  end

  def thoughts
    @thoughts ||= begin
      relation = team ? Thought.where(team: team) : Thought
      relation.order(created_at: :desc).limit(50)
    end
  end

  def thought_options
    thoughts.map { |t| [t.text.truncate(60), t.id] }
  end

  def weblinks
    @weblinks ||= begin
      relation = team ? Weblink.where(team: team) : Weblink
      relation.order(created_at: :desc).limit(50)
    end
  end

  def weblink_options
    weblinks.map { |w| [w.name, w.id] }
  end
end
