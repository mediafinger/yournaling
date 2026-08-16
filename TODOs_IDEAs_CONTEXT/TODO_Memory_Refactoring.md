# Implementation Plan: Refactor Memory to Reuse Picture Select and Insight Attachment Code

Refactor `Memory` to reuse the rich Stimulus picture selection and inline insight creation workflow developed for `Chronicle`.

## User Review Required
> [!NOTE]
> `Memory` will gain the ability to attach pictures visually (with thumbnail previews and inline upload) as well as create new Locations and Weblinks inline during Memory creation and updates.

---

## Proposed Changes

### 1. Reusable Insight Resolving Service
#### [NEW] [`app/services/insight_resolver.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/insight_resolver.rb)
- Encapsulates resolving existing insights (by ID or URL-safe ID) or creating new ones (with event tracking and image conversion) for:
  - `resolve_picture(team:, start_date:, visibility:, picture_id:, picture_file:, picture_name:, user:)`
  - `resolve_location(team:, start_date:, visibility:, location_id:, location_name:, location_address:, location_country_code:, location_url:, location_description:, user:)`
  - `resolve_thought(team:, start_date:, visibility:, thought_id:, thought_text:, user:)`
  - `resolve_weblink(team:, start_date:, visibility:, weblink_id:, weblink_name:, weblink_url:, weblink_description:, user:)`

---

### 2. Model Concerns
#### [MODIFY] [`app/models/concerns/chronicle_attachable_insights.rb`](file:///Users/andy/Dropbox/www/yournaling/app/models/concerns/chronicle_attachable_insights.rb)
- Delegate insight creation and resolution to `InsightResolver`, then create `chronicle_entries`.

#### [NEW] [`app/models/concerns/memory_attachable_insights.rb`](file:///Users/andy/Dropbox/www/yournaling/app/models/concerns/memory_attachable_insights.rb)
- Add attr_accessors for `picture_file`, `picture_name`, `location_name`, `location_address`, `location_url`, `weblink_name`, `weblink_url`, `weblink_description`.
- Provide `attach_insights(params, user:)` to assign `picture=`, `location=`, `weblink=` directly to the memory.

#### [MODIFY] [`app/models/memory.rb`](file:///Users/andy/Dropbox/www/yournaling/app/models/memory.rb)
- Include `MemoryAttachableInsights`.

---

### 3. Reusable Form ViewComponents
#### [NEW] [`app/view_components/picture_select_field_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/picture_select_field_component.rb)
- Encapsulates the Pico CSS `<details class="dropdown">` with image previews, Stimulus controller hooks, and file upload preview.

#### [MODIFY] [`app/view_components/chronicle_attach_insights_form_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/chronicle_attach_insights_form_component.rb)
- Render `PictureSelectFieldComponent` for the picture attachment section.

#### [MODIFY] [`app/views/current_teams/memories/_form.html.slim`](file:///Users/andy/Dropbox/www/yournaling/app/views/current_teams/memories/_form.html.slim)
- Add `data: { controller: "picture-select" }` to the form.
- Render `PictureSelectFieldComponent` for selecting/uploading a picture.
- Provide inline creation inputs for Location and Weblink.

---

### 4. Controller Updates
#### [MODIFY] [`app/controllers/current_teams/memories_controller.rb`](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/memories_controller.rb)
- Permit insight creation keys in `create_params` and `update_params`.
- Call `@memory.attach_insights(...)` upon creation and update.

---

## Verification Plan

### Automated Tests
- `bin/mcp_rspec spec/requests/current_teams/memories_request_spec.rb`
- `bin/mcp_rspec spec/models/memory_spec.rb`
- `bin/mcp_rspec spec/requests/current_teams/chronicles_request_spec.rb`
- Full suite: `bin/mcp_rake_ci`
