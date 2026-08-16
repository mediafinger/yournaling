# Implementation Plan: Refactor Memory to Reuse Insight Attachment & Picture Selection

Following the Chronicle architecture merged in commit `be74754`, this plan refactors `Memory` forms and controllers to reuse the service-based insight attachment pattern and rich Stimulus picture selection without polluting models with sidecar concerns or altering Memory's core data model.

## Core Design Principles
1. **No Extra Capabilities on `Memory` Model**: `Memory` retains its existing 1-to-1 direct relationships (`belongs_to :picture`, `belongs_to :location`, `belongs_to :thought`, `belongs_to :weblink`). It does **not** gain polymorphic entries or multiple attachments.
2. **No Model Concerns / Fake Accessors**: Unlike early prototypes, domain models remain clean. Parameter extraction, insight resolution, and event logging are handled via dedicated service objects.
3. **DRY Service Layer**: Shared insight creation and resolution logic (ActiveStorage upload conversion, event tracking, team scoping, validation error propagation) is extracted into a reusable `InsightResolver`, leveraged by both `ChronicleInsightAttacher` and `MemoryInsightAttacher`.
4. **Modern UI & Rich Form Controls**: Memory forms replace bare, un-scoped `<select>` dropdowns with the searchable Pico CSS thumbnail dropdown and live upload preview via the Stimulus `picture-select` controller.
5. **Transactional Integrity**: Controller operations run inside `ActiveRecord::Base.transaction`, ensuring child validation failures rollback cleanly and render inline error messages via `ActiveRecord::RecordInvalid`.

---

## Proposed Changes

### 1. Shared Service Layer: `InsightResolver`

#### [NEW] [`app/services/insight_resolver.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/insight_resolver.rb)
- Encapsulates resolving existing insights (by ID or URL-safe ID) or creating new ones (with event tracking, multi-tenant scoping, and image conversion):
  - `resolve_picture(team:, date:, visibility:, picture_id:, picture_file:, picture_name:, user:)`
  - `resolve_location(team:, date:, visibility:, location_id:, location_name:, location_address:, location_country_code:, location_url:, location_description:, user:)`
  - `resolve_thought(team:, date:, visibility:, thought_id:, thought_text:, user:)`
  - `resolve_weblink(team:, date:, visibility:, weblink_id:, weblink_name:, weblink_url:, weblink_description:, user:)`
- Implements `merge_errors_and_raise!(target_record, record, fallback_attribute)` to copy validation errors to the parent record and trigger transaction rollback with `ActiveRecord::RecordInvalid`.

#### [MODIFY] [`app/services/chronicle_insight_attacher.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/chronicle_insight_attacher.rb)
- Delegate insight creation and resolution to `InsightResolver`.
- On successful resolution, create polymorphic `chronicle.entries.create!(entry: resolved_record, team: team)`.

#### [NEW] [`app/services/memory_insight_attacher.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/memory_insight_attacher.rb)
- Companion service dedicated to `Memory`.
- Extracts insight params via `extract_insight_params!(attrs)`.
- Calls `InsightResolver` and directly assigns resolved records to the memory's `belongs_to` associations:
  - `memory.picture = resolved_picture`
  - `memory.location = resolved_location`
  - `memory.thought = resolved_thought`
  - `memory.weblink = resolved_weblink`
- Saves the memory within the transaction, propagating any child or parent validation errors.

---

### 2. Controller Updates & Strong Parameters

#### [NEW] [`app/controllers/concerns/memory_form_handling.rb`](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/memory_form_handling.rb)
- Implements `permit_memory_params(additional_keys: [])` to safely permit `memo`, `visibility`, `team_id`, plus `MemoryInsightAttacher::INSIGHT_PARAM_KEYS`.

#### [MODIFY] [`app/controllers/current_teams/memories_controller.rb`](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/memories_controller.rb)
- Include `MemoryFormHandling`.
- **Create**:
  - Extract insight attributes from `memory_params`.
  - Wrap creation and attachment in `ActiveRecord::Base.transaction`.
  - Call `MemoryInsightAttacher.call(memory: @memory, params: insight_attrs, user: current_user)`.
  - Rescue `ActiveRecord::RecordInvalid` and render `:new, status: :unprocessable_content`.
- **Update**:
  - Extract insight attributes from `memory_params`.
  - Wrap update and attachment in `ActiveRecord::Base.transaction`.
  - Call `MemoryInsightAttacher.call(memory: @memory, params: insight_attrs, user: current_user)`.
  - Rescue `ActiveRecord::RecordInvalid` and render `:edit, status: :unprocessable_content`.

---

### 3. Reusable Form ViewComponents & UI Refactoring

#### [NEW] [`app/view_components/picture_select_field_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/picture_select_field_component.rb)
- Extracts the picture picker UI out of `ChronicleAttachInsightsFormComponent`:
  - Scoped picture queries with `with_attached_file` and limits to avoid loading all DB records.
  - Pico CSS `<details class="dropdown">` with image thumbnail list.
  - File upload field with live thumbnail preview via Stimulus `picture-select`.
  - Optional picture name text input.

#### [MODIFY] [`app/view_components/chronicle_attach_insights_form_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/chronicle_attach_insights_form_component.rb)
- Replace inline picture selection markup with `render PictureSelectFieldComponent.new(form: @form, team: scope_team, selected_picture: selected_picture)`.

#### [MODIFY] [`app/views/current_teams/memories/_form.html.slim`](file:///Users/andy/Dropbox/www/yournaling/app/views/current_teams/memories/_form.html.slim)
- Attach `data: { controller: "picture-select" }` to the form container.
- Replace `form.select :picture_id, Picture.pluck(...)` with `render PictureSelectFieldComponent.new(form: form, team: current_team, selected_picture: memory.picture)`.
- Replace raw unscoped select dropdowns for Location, Thought, and Weblink with scoped selects (limited to current team) and inline creation inputs (name, address, country code, URL, etc.).

---

## Verification Plan

### Automated Tests
1. **Service Specs**:
   - `bin/mcp_rspec spec/services/insight_resolver_spec.rb` (Testing resolution, creation, upload conversion, error propagation, multi-tenancy).
   - `bin/mcp_rspec spec/services/memory_insight_attacher_spec.rb` (Testing direct assignment to memory attributes, error rollback).
   - `bin/mcp_rspec spec/services/chronicle_insight_attacher_spec.rb` (Ensuring zero regressions for chronicles).
2. **ViewComponent Specs**:
   - `bin/mcp_rspec spec/view_components/picture_select_field_component_spec.rb`
   - `bin/mcp_rspec spec/view_components/chronicle_attach_insights_form_component_spec.rb`
3. **Request Specs**:
   - `bin/mcp_rspec spec/requests/current_teams/memories_request_spec.rb` (Create and update with existing insights, newly uploaded pictures, inline created locations/thoughts/weblinks, and validation failure rendering).
   - `bin/mcp_rspec spec/requests/current_teams/chronicles_request_spec.rb`
4. **Full CI Suite**:
   - `bin/mcp_rake_ci` (Verifying all specs, RuboCop auto-correction, and DB Doctor validation).
