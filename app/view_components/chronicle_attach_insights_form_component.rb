# frozen_string_literal: true

class ChronicleAttachInsightsFormComponent < ApplicationComponent
  slim_template <<~SLIM
    = render PictureSelectFieldComponent.new(form: @form, team: scope_team, scope: @scope)

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

  def initialize(form:, chronicle:, scope: "current_team")
    @form = form
    @chronicle = chronicle
    @scope = scope
  end

  def scope_team
    @scope == "admin" ? @chronicle.team : current_team
  end

  def locations
    @locations ||= begin
      scope_team = @scope == "admin" ? @chronicle.team : current_team
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
      scope_team = @scope == "admin" ? @chronicle.team : current_team
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
      scope_team = @scope == "admin" ? @chronicle.team : current_team
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
