# frozen_string_literal: true

class ChronicleAttachInsightsFormComponent < ApplicationComponent
  slim_template <<~SLIM
    = render PictureSelectFieldComponent.new(form: @form, team: scope_team, scope: @scope)

    fieldset data-controller="insight-select"
      legend Attach Location (Optional)
      div
        = label_tag "\#{@form.object_name}_location_id", "Select Existing Location"
        = select_tag "\#{@form.object_name}[location_id]", options_for_select([["None (no location)", ""]] + location_options, selected_location_id), id: "\#{@form.object_name}_location_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" open=(location_details_open ? "open" : nil) style="margin-top: 1rem;"
        summary Or Create New Location
        div style="margin-top: 0.75rem;"
          div
            = label_tag "\#{@form.object_name}_location_name", "Location Name"
            = text_field_tag "\#{@form.object_name}[location_name]", location_name_value, id: "\#{@form.object_name}_location_name", placeholder: "e.g. Cabo de Gata Camping", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_location_country_code", "Country"
            = select_tag "\#{@form.object_name}[location_country_code]", options_for_select(country_options, selected_country_code), include_blank: "Select Country...", id: "\#{@form.object_name}_location_country_code", data: { insight_select_target: "input", action: "change->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_location_address", "Address"
            = text_field_tag "\#{@form.object_name}[location_address]", location_address_value, id: "\#{@form.object_name}_location_address", placeholder: "e.g. Playa de los Genoveses, San Jose", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_location_url", "Map / Website URL"
            = url_field_tag "\#{@form.object_name}[location_url]", location_url_value, id: "\#{@form.object_name}_location_url", placeholder: "e.g. https://maps.google.com/...", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }

    fieldset data-controller="insight-select"
      legend Attach Thought (Optional)
      div
        = label_tag "\#{@form.object_name}_thought_id", "Select Existing Thought"
        = select_tag "\#{@form.object_name}[thought_id]", options_for_select([["None (no thought)", ""]] + thought_options, selected_thought_id), id: "\#{@form.object_name}_thought_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" open=(thought_details_open ? "open" : nil) style="margin-top: 1rem;"
        summary Or Create New Thought
        div style="margin-top: 0.75rem;"
          = label_tag "\#{@form.object_name}_thought_text", "Thought Text"
          = text_area_tag "\#{@form.object_name}[thought_text]", thought_text_value, id: "\#{@form.object_name}_thought_text", rows: 3, placeholder: "Write a memorable thought or reflection...", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }

    fieldset data-controller="insight-select"
      legend Attach Weblink (Optional)
      div
        = label_tag "\#{@form.object_name}_weblink_id", "Select Existing Weblink"
        = select_tag "\#{@form.object_name}[weblink_id]", options_for_select([["None (no weblink)", ""]] + weblink_options, selected_weblink_id), id: "\#{@form.object_name}_weblink_id", data: { insight_select_target: "select", action: "change->insight-select#onSelectChange" }
      details data-insight-select-target="details" open=(weblink_details_open ? "open" : nil) style="margin-top: 1rem;"
        summary Or Create New Weblink
        div style="margin-top: 0.75rem;"
          div
            = label_tag "\#{@form.object_name}_weblink_name", "Link Name"
            = text_field_tag "\#{@form.object_name}[weblink_name]", weblink_name_value, id: "\#{@form.object_name}_weblink_name", placeholder: "e.g. Route Planning Guide", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_weblink_url", "URL"
            = url_field_tag "\#{@form.object_name}[weblink_url]", weblink_url_value, id: "\#{@form.object_name}_weblink_url", placeholder: "e.g. https://route-planner.example.com", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
          div style="margin-top: 0.5rem;"
            = label_tag "\#{@form.object_name}_weblink_description", "Description (Optional)"
            = text_field_tag "\#{@form.object_name}[weblink_description]", weblink_description_value, id: "\#{@form.object_name}_weblink_description", placeholder: "Brief notes about the link", data: { insight_select_target: "input", action: "input->insight-select#onInputChange" }
  SLIM

  def initialize(form:, chronicle:, scope: "current_team")
    @form = form
    @chronicle = chronicle
    @scope = scope
  end

  def scope_team
    @scope == "admin" ? @chronicle.team : current_team
  end

  def selected_location_id
    nil
  end

  def selected_thought_id
    nil
  end

  def selected_weblink_id
    nil
  end

  def location_name_value
    @chronicle.respond_to?(:location_name) ? @chronicle.location_name : nil
  end

  def selected_country_code
    @chronicle.respond_to?(:location_country_code) ? @chronicle.location_country_code : nil
  end

  def location_address_value
    @chronicle.respond_to?(:location_address) ? @chronicle.location_address : nil
  end

  def location_url_value
    @chronicle.respond_to?(:location_url) ? @chronicle.location_url : nil
  end

  def thought_text_value
    @chronicle.respond_to?(:thought_text) ? @chronicle.thought_text : nil
  end

  def weblink_name_value
    @chronicle.respond_to?(:weblink_name) ? @chronicle.weblink_name : nil
  end

  def weblink_url_value
    @chronicle.respond_to?(:weblink_url) ? @chronicle.weblink_url : nil
  end

  def weblink_description_value
    @chronicle.respond_to?(:weblink_description) ? @chronicle.weblink_description : nil
  end

  def location_details_open
    return true if location_name_value.present? || selected_country_code.present? ||
                   location_address_value.present? || location_url_value.present?

    errors = @form.object.respond_to?(:errors) && @form.object.errors.any? ? @form.object.errors : @chronicle.errors
    errors.attribute_names.any? { |k| k.to_s.start_with?("location") }
  end

  def thought_details_open
    return true if thought_text_value.present?

    errors = @form.object.respond_to?(:errors) && @form.object.errors.any? ? @form.object.errors : @chronicle.errors
    errors.attribute_names.any? { |k| k.to_s.start_with?("thought") }
  end

  def weblink_details_open
    return true if weblink_name_value.present? || weblink_url_value.present? || weblink_description_value.present?

    errors = @form.object.respond_to?(:errors) && @form.object.errors.any? ? @form.object.errors : @chronicle.errors
    errors.attribute_names.any? { |k| k.to_s.start_with?("weblink") }
  end

  def country_options
    CountriesEnForSelectService.call.map { |k, v| [v, k] }
  end

  def locations
    @locations ||= begin
      relation = scope_team ? Location.where(team: scope_team) : Location
      relation.order(created_at: :desc).limit(50)
    end
  end

  def location_options
    locations.map do |l|
      label = @scope == "admin" && l.team ? "#{l.name} (#{l.team.name})" : l.name
      [label, l.id]
    end
  end

  def thoughts
    @thoughts ||= begin
      relation = scope_team ? Thought.where(team: scope_team) : Thought
      relation.order(created_at: :desc).limit(50)
    end
  end

  def thought_options
    thoughts.map do |t|
      label = @scope == "admin" && t.team ? "#{t.text.truncate(50)} (#{t.team.name})" : t.text.truncate(60)
      [label, t.id]
    end
  end

  def weblinks
    @weblinks ||= begin
      relation = scope_team ? Weblink.where(team: scope_team) : Weblink
      relation.order(created_at: :desc).limit(50)
    end
  end

  def weblink_options
    weblinks.map do |w|
      label = @scope == "admin" && w.team ? "#{w.name} (#{w.team.name})" : w.name
      [label, w.id]
    end
  end
end
