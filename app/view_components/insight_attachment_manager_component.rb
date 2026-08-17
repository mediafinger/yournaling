# frozen_string_literal: true

class InsightAttachmentManagerComponent < ApplicationComponent
  slim_template <<~'SLIM'
    fieldset data-controller="insight-manager" data-insight-manager-mode-value=@mode data-insight-manager-record-name-value=record_name data-insight-manager-create-location-url-value=create_location_url data-insight-manager-create-picture-url-value=create_picture_url data-insight-manager-create-thought-url-value=create_thought_url data-insight-manager-create-weblink-url-value=create_weblink_url
      legend
        h4 style="margin-bottom: 0.25rem;" Attached Insights
        p
          small style="color: var(--pico-muted-color);"
            - if @mode == "single"
              | Add up to 1 of each insight type (Location, Picture, Thought, Weblink).
            - else
              | Add insights to this chronicle.

      - if @mode == "single"
        = @form.hidden_field :location_id, data: { insight_manager_target: "locationIdInput" }
        = @form.hidden_field :picture_id, data: { insight_manager_target: "pictureIdInput" }
        = @form.hidden_field :thought_id, data: { insight_manager_target: "thoughtIdInput" }
        = @form.hidden_field :weblink_id, data: { insight_manager_target: "weblinkIdInput" }

      div data-insight-manager-target="attachedContainer" style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 1rem;"
        - if @record.respond_to?(:location) && @record.location.present?
          div data-insight-chip="true" data-type="location" data-id=@record.location.id style="display: inline-flex; align-items: center; justify-content: space-between; background: var(--pico-card-background-color); border: 1px solid var(--pico-muted-border-color); border-radius: 6px; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
            span style="margin-right: 0.75rem;"
              strong 📍 Location:&nbsp;
              = @record.location.name
            button type="button" class="outline secondary" data-action="click->insight-manager#removeInsight" data-type="location" style="padding: 0.2rem 0.5rem; margin-bottom: 0; font-size: 0.8rem; line-height: 1;" title="Remove" ✕

        - if @record.respond_to?(:picture) && @record.picture.present?
          div data-insight-chip="true" data-type="picture" data-id=@record.picture.id style="display: inline-flex; align-items: center; justify-content: space-between; background: var(--pico-card-background-color); border: 1px solid var(--pico-muted-border-color); border-radius: 6px; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
            span style="display: flex; align-items: center; margin-right: 0.75rem;"
              - if @record.picture.thumbnail
                img src=rails_representation_path(@record.picture.thumbnail) style="width: 40px; height: 30px; object-fit: cover; border-radius: 3px; margin-right: 0.5rem;" alt=""
              span
                strong 🖼 Picture:&nbsp;
                = @record.picture.name
            button type="button" class="outline secondary" data-action="click->insight-manager#removeInsight" data-type="picture" style="padding: 0.2rem 0.5rem; margin-bottom: 0; font-size: 0.8rem; line-height: 1;" title="Remove" ✕

        - if @record.respond_to?(:thought) && @record.thought.present?
          div data-insight-chip="true" data-type="thought" data-id=@record.thought.id style="display: inline-flex; align-items: center; justify-content: space-between; background: var(--pico-card-background-color); border: 1px solid var(--pico-muted-border-color); border-radius: 6px; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
            span style="margin-right: 0.75rem;"
              strong 💭 Thought:&nbsp;
              = @record.thought.text.truncate(60)
            button type="button" class="outline secondary" data-action="click->insight-manager#removeInsight" data-type="thought" style="padding: 0.2rem 0.5rem; margin-bottom: 0; font-size: 0.8rem; line-height: 1;" title="Remove" ✕

        - if @record.respond_to?(:weblink) && @record.weblink.present?
          div data-insight-chip="true" data-type="weblink" data-id=@record.weblink.id style="display: inline-flex; align-items: center; justify-content: space-between; background: var(--pico-card-background-color); border: 1px solid var(--pico-muted-border-color); border-radius: 6px; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
            span style="margin-right: 0.75rem;"
              strong 🔗 Weblink:&nbsp;
              = @record.weblink.name
            button type="button" class="outline secondary" data-action="click->insight-manager#removeInsight" data-type="weblink" style="padding: 0.2rem 0.5rem; margin-bottom: 0; font-size: 0.8rem; line-height: 1;" title="Remove" ✕

      / - # "+ Add Insight" Dropdown
      details.dropdown data-insight-manager-target="dropdown" style="margin-bottom: 1rem; display: inline-block;"
        summary role="button" class="outline" style="margin-bottom: 0; padding: 0.35rem 0.85rem; font-size: 0.9rem;" + Add Insight
        ul style="min-width: 260px;"
          li data-insight-manager-target="locationMenuItem"
            span style="display: block; padding: 0.35rem 0.75rem 0.15rem; font-weight: bold; font-size: 0.85rem; color: var(--pico-color);" 📍 Location
            div style="padding-left: 0.5rem;"
              a href="#" data-action="click->insight-manager#openCreate" data-type="location" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" + Create New Location
              a href="#" data-action="click->insight-manager#openSelect" data-type="location" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" Select Existing Location...
            hr style="margin: 0.35rem 0;"

          li data-insight-manager-target="pictureMenuItem"
            span style="display: block; padding: 0.35rem 0.75rem 0.15rem; font-weight: bold; font-size: 0.85rem; color: var(--pico-color);" 🖼 Picture
            div style="padding-left: 0.5rem;"
              a href="#" data-action="click->insight-manager#openCreate" data-type="picture" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" + Upload New Picture
              a href="#" data-action="click->insight-manager#openSelect" data-type="picture" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" Select Existing Picture...
            hr style="margin: 0.35rem 0;"

          li data-insight-manager-target="thoughtMenuItem"
            span style="display: block; padding: 0.35rem 0.75rem 0.15rem; font-weight: bold; font-size: 0.85rem; color: var(--pico-color);" 💭 Thought
            div style="padding-left: 0.5rem;"
              a href="#" data-action="click->insight-manager#openCreate" data-type="thought" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" + Create New Thought
              a href="#" data-action="click->insight-manager#openSelect" data-type="thought" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" Select Existing Thought...
            hr style="margin: 0.35rem 0;"

          li data-insight-manager-target="weblinkMenuItem"
            span style="display: block; padding: 0.35rem 0.75rem 0.15rem; font-weight: bold; font-size: 0.85rem; color: var(--pico-color);" 🔗 Weblink
            div style="padding-left: 0.5rem;"
              a href="#" data-action="click->insight-manager#openCreate" data-type="weblink" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" + Create New Weblink
              a href="#" data-action="click->insight-manager#openSelect" data-type="weblink" style="display: block; padding: 0.25rem 0.75rem; font-size: 0.9rem;" Select Existing Weblink...

      / - # In-Flow Drawer Card
      article data-insight-manager-target="drawer" style="display: none; border: 1px solid var(--pico-muted-border-color); border-radius: 8px; padding: 1.25rem; margin-top: 1rem; margin-bottom: 1rem;"
        div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;"
          h4 data-insight-manager-target="drawerTitle" style="margin-bottom: 0;"
          button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" style="margin-bottom: 0; padding: 0.25rem 0.5rem; font-size: 0.85rem;" title="Close" ✕

        div data-insight-manager-target="drawerError" style="display: none;"
        div data-insight-manager-target="drawerFormContainer"

      / - # Templates for In-Flow Creation
      template data-insight-manager-target="locationTemplate"
        form
          div
            label for="drawer_location_name" Location Name
            input type="text" id="drawer_location_name" name="location[name]" placeholder="e.g. Cabo de Gata Camping" required=true
          div style="margin-top: 0.5rem;"
            label for="drawer_location_country_code" Country
            select id="drawer_location_country_code" name="location[country_code]" required=true
              - CountriesEnForSelectService.call.each do |code, name|
                option value=code selected=(code == "de") = name
          div data-controller="tabs" style="margin-top: 1rem; margin-bottom: 1rem;"
            label
              strong Location Details (Choose one)
            div role="group" style="margin-bottom: 0.75rem;"
              button type="button" data-tabs-target="tab" data-tab-index="0" data-action="click->tabs#select" Address
              button type="button" data-tabs-target="tab" data-tab-index="1" data-action="click->tabs#select" class="outline secondary" GPS Coordinates
              button type="button" data-tabs-target="tab" data-tab-index="2" data-action="click->tabs#select" class="outline secondary" Map / Web URL
            div data-tabs-target="panel"
              label for="drawer_location_address" Street Address / City
              input type="text" id="drawer_location_address" name="location[address]" placeholder="e.g. Playa de los Genoveses, San Jose"
            div data-tabs-target="panel" style="display: none;"
              div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;"
                div
                  label for="drawer_location_lat" Latitude
                  input type="text" id="drawer_location_lat" name="location[lat]" placeholder="e.g. 36.7491"
                div
                  label for="drawer_location_long" Longitude
                  input type="text" id="drawer_location_long" name="location[long]" placeholder="e.g. -2.2425"
            div data-tabs-target="panel" style="display: none;"
              label for="drawer_location_url" Map / Web URL
              input type="url" id="drawer_location_url" name="location[url]" placeholder="e.g. https://maps.google.com/..."
          div style="margin-top: 0.5rem;"
            label for="drawer_location_date" Date
            input type="date" id="drawer_location_date" name="location[date]"
          div style="margin-top: 0.5rem;"
            label for="drawer_location_description" Notes / Description (Optional)
            textarea id="drawer_location_description" name="location[description]" placeholder="Additional details about this place..."
          div style="display: flex; gap: 0.75rem; margin-top: 1rem;"
            button type="button" data-action="click->insight-manager#submitCreate" data-type="location" Create Location
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="pictureTemplate"
        form data-controller="picture-select"
          div
            label for="drawer_picture_file" Image File
            input type="file" id="drawer_picture_file" name="picture[file]" accept=allowed_image_types_accept required=true data-picture-select-target="fileInput" data-action="change->picture-select#updateFilePreview"
            div style="margin-top: 0.5rem;"
              img data-picture-select-target="filePreview" style="display: none; max-width: 240px; max-height: 180px; object-fit: cover; border-radius: 4px;" alt="Selected image preview"
          div style="margin-top: 0.5rem;"
            label for="drawer_picture_name" Picture Name (Optional)
            input type="text" id="drawer_picture_name" name="picture[name]" placeholder="Defaults to image file name" data-picture-select-target="pictureNameInput"
          div style="margin-top: 0.5rem;"
            label for="drawer_picture_date" Date
            input type="date" id="drawer_picture_date" name="picture[date]"
          div style="display: flex; gap: 0.75rem; margin-top: 1rem;"
            button type="button" data-action="click->insight-manager#submitCreate" data-type="picture" Create Picture
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="thoughtTemplate"
        form
          div
            label for="drawer_thought_text" Thought Text
            textarea id="drawer_thought_text" name="thought[text]" rows="4" placeholder="Write a memorable thought, quote, or reflection..." required=true
          div style="margin-top: 0.5rem;"
            label for="drawer_thought_date" Date
            input type="date" id="drawer_thought_date" name="thought[date]"
          div style="display: flex; gap: 0.75rem; margin-top: 1rem;"
            button type="button" data-action="click->insight-manager#submitCreate" data-type="thought" Create Thought
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="weblinkTemplate"
        form
          div
            label for="drawer_weblink_name" Link Name
            input type="text" id="drawer_weblink_name" name="weblink[name]" placeholder="e.g. Route Planning Guide" required=true
          div style="margin-top: 0.5rem;"
            label for="drawer_weblink_url" URL
            input type="url" id="drawer_weblink_url" name="weblink[url]" placeholder="e.g. https://route-planner.example.com" required=true
          div style="margin-top: 0.5rem;"
            label for="drawer_weblink_description" Description (Optional)
            textarea id="drawer_weblink_description" name="weblink[description]" placeholder="Brief notes or context about this link..."
          div style="margin-top: 0.5rem;"
            label for="drawer_weblink_date" Date
            input type="date" id="drawer_weblink_date" name="weblink[date]"
          div style="display: flex; gap: 0.75rem; margin-top: 1rem;"
            button type="button" data-action="click->insight-manager#submitCreate" data-type="weblink" Create Weblink
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      / - # Templates for Existing Selection
      template data-insight-manager-target="existingLocationTemplate"
        div
          label for="select_existing_location" Select from your team's locations:
          select id="select_existing_location" data-type="location" style="margin-bottom: 1rem;"
            option value="" -- Choose a Location --
            - team_locations.each do |loc|
              option value=loc.id = "#{loc.name} (#{loc.country_code&.upcase})"
          div style="display: flex; gap: 0.75rem;"
            button type="button" data-action="click->insight-manager#selectExisting" Add Location
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="existingPictureTemplate"
        div
          label for="select_existing_picture" Select from your team's pictures:
          select id="select_existing_picture" data-type="picture" style="margin-bottom: 1rem;"
            option value="" -- Choose a Picture --
            - team_pictures.each do |pic|
              option value=pic.id data-thumb-url=(rails_representation_path(pic.thumbnail) if pic.thumbnail) = pic.name
          div style="display: flex; gap: 0.75rem;"
            button type="button" data-action="click->insight-manager#selectExisting" Add Picture
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="existingThoughtTemplate"
        div
          label for="select_existing_thought" Select from your team's thoughts:
          select id="select_existing_thought" data-type="thought" style="margin-bottom: 1rem;"
            option value="" -- Choose a Thought --
            - team_thoughts.each do |th|
              option value=th.id = th.text.truncate(60)
          div style="display: flex; gap: 0.75rem;"
            button type="button" data-action="click->insight-manager#selectExisting" Add Thought
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel

      template data-insight-manager-target="existingWeblinkTemplate"
        div
          label for="select_existing_weblink" Select from your team's weblinks:
          select id="select_existing_weblink" data-type="weblink" style="margin-bottom: 1rem;"
            option value="" -- Choose a Weblink --
            - team_weblinks.each do |wl|
              option value=wl.id = "#{wl.name} (#{wl.url})"
          div style="display: flex; gap: 0.75rem;"
            button type="button" data-action="click->insight-manager#selectExisting" Add Weblink
            button type="button" class="outline secondary" data-action="click->insight-manager#closeDrawer" Cancel
  SLIM

  def initialize(form:, scope: "current_team", mode: "single")
    @form = form
    @record = form.object
    @scope = scope
    @mode = mode.to_s
  end

  def record_name
    @record.model_name.param_key
  end

  def allowed_image_types_accept
    Picture::ALLOWED_IMAGE_TYPES.map { |type| ".#{type}" }.join(", ")
  end

  def team
    @record.team || (helpers.current_team if helpers.respond_to?(:current_team))
  end

  def team_locations
    if team
      team.locations.order(name: :asc)
    elsif @scope == "admin"
      Location.order(name: :asc)
    else
      Location.none
    end
  end

  def team_pictures
    if team
      team.pictures.order(created_at: :desc)
    elsif @scope == "admin"
      Picture.order(created_at: :desc)
    else
      Picture.none
    end
  end

  def team_thoughts
    if team
      team.thoughts.order(created_at: :desc)
    elsif @scope == "admin"
      Thought.order(created_at: :desc)
    else
      Thought.none
    end
  end

  def team_weblinks
    if team
      team.weblinks.order(name: :asc)
    elsif @scope == "admin"
      Weblink.order(name: :asc)
    else
      Weblink.none
    end
  end

  def create_location_url
    @scope == "admin" ? "/admin/locations.json" : "/current_team/locations.json"
  end

  def create_picture_url
    @scope == "admin" ? "/admin/pictures.json" : "/current_team/pictures.json"
  end

  def create_thought_url
    @scope == "admin" ? "/admin/thoughts.json" : "/current_team/thoughts.json"
  end

  def create_weblink_url
    @scope == "admin" ? "/admin/weblinks.json" : "/current_team/weblinks.json"
  end
end
