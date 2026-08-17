# Implementation Plan: Refactor Memory to Reuse Insight Attachment & Picture Selection

Following the Chronicle architecture merged in commit `be74754`, this plan refactors `Memory` forms and controllers to reuse the service-based insight attachment pattern and rich Stimulus picture selection without polluting models with sidecar concerns or altering Memory's core data model.

## Core Design Principles

1. **Attachment Capacity — 1-to-1 (Memory) vs. 1-to-Many (Chronicle)**:
   - `Memory` can only attach **at most 1 of each supported insight** via its direct foreign keys (`belongs_to :picture`, `belongs_to :location`, `belongs_to :thought`, `belongs_to :weblink`). It does **not** gain polymorphic entries or multiple attachments of the same type.
   - `Chronicle` attaches **multiple entries** of any type via polymorphic join records (`has_many :entries, class_name: "ChronicleEntry"`).
2. **Uniform Detachment Behavior Across All Insights**:
   - All insights (Picture, Location, Thought, Weblink) behave identically when being removed or replaced:
     - Submitting a blank ID / choosing `"None (no [insight])"` explicitly detaches/clears the association (`memory.picture = nil`, `memory.location = nil`, `memory.thought = nil`, `memory.weblink = nil`).
     - Selecting a different record or creating a new inline insight replaces the existing association.
3. **Consistent UI & Form Controls for All Insights**:
   - All 4 insight types (Picture, Location, Thought, Weblink) share identical UI ergonomics:
     - Dedicated selection dropdown with team scoping (`.limit(50)`) and an explicit `"None (no ...)"` option.
     - Collapsible `<details>` section for inline creation ("Or Create New [Insight]" / "Or Upload New Picture").
     - Interactive mutual auto-clearing via Stimulus (`picture-select` and `insight-select` controllers) so choosing an existing record resets creation inputs, and typing into creation inputs resets the dropdown.
     - Persistent open state (`<details open>`) on validation failures when inline fields contain user input or validation errors.
4. **No Model Concerns / Fake Accessors**:
   - Domain models remain clean. Parameter extraction, insight resolution, and event logging are handled via dedicated service objects.
   - Remove leftover `attr_accessor` declarations on `Chronicle`.
5. **DRY Service Layer**:
   - Shared insight creation and resolution logic (ActiveStorage upload conversion, event tracking, team scoping, validation error propagation) is extracted into a reusable `InsightResolver`, leveraged by both `ChronicleInsightAttacher` and `MemoryInsightAttacher`.
6. **Transactional Integrity & Precise Error Mapping**:
   - Controller operations run inside `ActiveRecord::Base.transaction`.
   - Child validation errors are mapped directly to their corresponding form fields (e.g., `location_url`, `weblink_url`), and collapsible sections persist open on validation failure so users immediately see error feedback.
7. **Robust Parameter Handling**:
   - Parameters are permitted cleanly without destructive stripping (avoiding `compact_blank` so blank submissions trigger proper presence validation without silently bypassing changes or raising false positives).

---

## Detailed Task Breakdown

### 1. Shared Service Layer: `InsightResolver` & Attachers

#### [NEW/MAINTAIN] [`app/services/insight_resolver.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/insight_resolver.rb)
- Encapsulates resolving existing insights (by ID or URL-safe ID) or creating new ones (with event tracking, multi-tenant scoping, and image conversion):
  - `resolve_picture_upload(picture_file:, picture_name: nil)`
  - `find_existing_picture(picture_id)`
  - `resolve_location(location_id: nil, location_name: nil, location_address: nil, location_country_code: nil, location_url: nil, location_description: nil)`
  - `resolve_thought(thought_id: nil, thought_text: nil)`
  - `resolve_weblink(weblink_id: nil, weblink_name: nil, weblink_url: nil, weblink_description: nil)`
- **Precise Error Mapping**:
  - Update `merge_errors_and_raise!(record, prefix)` to map child validation errors directly to their corresponding prefixed field name on the parent (e.g., if a location's URL is invalid, map the error to `:location_url` rather than a generic `:location_name`), falling back to the prefix if unmapped.

#### [MODIFY] [`app/services/chronicle_insight_attacher.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/chronicle_insight_attacher.rb)
- Delegates resolution to `InsightResolver`.
- On successful resolution, creates polymorphic `chronicle.entries.create!(entry: resolved_record, team: team)`.

#### [NEW/MAINTAIN] [`app/services/memory_insight_attacher.rb`](file:///Users/andy/Dropbox/www/yournaling/app/services/memory_insight_attacher.rb)
- Companion service dedicated to `Memory` (enforcing max 1 of each insight type).
- Extracts insight params via `extract_insight_params!(attrs)`.
- Validates **Mutual Exclusivity** (Option C): ensures callers do not supply both an existing ID and inline creation attributes for the same insight type.
- Symmetrically handles assignment and detachment across **all insight types**:
  - If a user selects "None" (blank ID `""` / `params.key?(:..._id)` with blank value), detaches the corresponding association (`memory.picture = nil`, `memory.location = nil`, `memory.thought = nil`, `memory.weblink = nil`).
  - If an inline insight is created or an existing insight is selected, assigns the resolved record to `memory.picture`, `memory.location`, `memory.thought`, or `memory.weblink`.
- Saves the memory within the transaction and raises `ActiveRecord::RecordInvalid` on any validation failure.

---

### 2. Controller & Parameter Refinements

#### [MODIFY] [`app/controllers/current_teams/memories_controller.rb`](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/memories_controller.rb)
- **Remove `compact_blank`**: Ensure `@memory.assign_attributes(attrs)` receives the raw permitted parameters so clearing required fields (like `memo: ""`) triggers presence validation rather than silently leaving the old value intact.
- **Transactional Safety**:
  - In `#create`: Wrap `create_with_event` and `MemoryInsightAttacher.call` in `ActiveRecord::Base.transaction`.
  - In `#update`: Wrap `update_with_event` and `MemoryInsightAttacher.call` in `ActiveRecord::Base.transaction`.
  - Rescue `ActiveRecord::RecordInvalid` and re-render `:new` / `:edit` with `status: :unprocessable_content`.

---

### 3. ViewComponents & UI Integration

#### [NEW/MAINTAIN] [`app/view_components/picture_select_field_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/picture_select_field_component.rb)
- Searchable thumbnail dropdown scoped to team (`Picture.where(team: ...).limit(50)`) with `"None (no picture)"` option.
- File upload with live image preview in collapsible `<details>`.
- Mutual auto-clearing via Stimulus `picture-select` controller.

#### [MODIFY] [`app/view_components/memory_attach_insights_form_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/memory_attach_insights_form_component.rb)
- **Consistent Insight Form Controls**:
  - Provide symmetrical controls across all 4 insights:
    - Picture: `PictureSelectFieldComponent` thumbnail dropdown + upload details.
    - Location: Scoped select (`"None (no location)"`) + collapsible `<details>` with Location Name, Address, Map/Website URL, Description, and **Mandatory Country Code Dropdown** (`CountriesEnForSelectService.call.map { |k, v| [v, k] }`).
    - Thought: Scoped select (`"None (no thought)"`) + collapsible `<details>` with Thought Text.
    - Weblink: Scoped select (`"None (no weblink)"`) + collapsible `<details>` with Link Name, URL, Description.
- **Open `<details>` on Validation Failures / Prefilled Input**:
  - Check if any child fields in the section have errors or submitted values; if so, render `<details open>` so the user immediately sees invalid input and error messages.
- **Interactive Mutual Auto-Clearing**:
  - Uses `insight-select` Stimulus controller to clear text inputs when a dropdown option is picked and clear the dropdown when typing in text fields.

#### [MODIFY] [`app/view_components/chronicle_attach_insights_form_component.rb`](file:///Users/andy/Dropbox/www/yournaling/app/view_components/chronicle_attach_insights_form_component.rb)
- Align Location creation form with `country_code` select dropdown.

---

### 4. Code Cleanliness & Model Hygiene

#### [MODIFY] [`app/models/chronicle.rb`](file:///Users/andy/Dropbox/www/yournaling/app/models/chronicle.rb)
- Remove `attr_accessor(*ChronicleInsightAttacher::INSIGHT_PARAM_KEYS)` as form fields are now handled through unbound parameters and service objects.

#### [MODIFY] [`app/models/memory.rb`](file:///Users/andy/Dropbox/www/yournaling/app/models/memory.rb)
- Add missing `# frozen_string_literal: true` at the top of the file.

---

## Verification & Regression Test Plan

### Automated Tests
1. **Service Specs**:
   - [`spec/services/insight_resolver_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/services/insight_resolver_spec.rb):
     - Test upload conversion, record resolution, event creation, tenant scoping, and precise field error propagation.
   - [`spec/services/memory_insight_attacher_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/services/memory_insight_attacher_spec.rb):
     - Test direct assignment to `belongs_to` associations (max 1 of each type).
     - Test detachment for **all insight types** (picture, location, thought, weblink) when selecting "None" / blank ID.
     - Test mutual exclusivity enforcement (raising 422 when providing both existing ID and inline creation).
     - Test transaction rollback on failure.
   - [`spec/services/chronicle_insight_attacher_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/services/chronicle_insight_attacher_spec.rb):
     - Verify zero regressions for chronicle entries (attaching multiple entries).
2. **ViewComponent Specs**:
   - [`spec/view_components/picture_select_field_component_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/view_components/picture_select_field_component_spec.rb)
   - [`spec/view_components/memory_attach_insights_form_component_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/view_components/memory_attach_insights_form_component_spec.rb):
     - Test rendering of mandatory country code dropdown for location.
     - Test that `<details>` renders with `open` attribute when errors or prefilled inputs are present.
     - Test uniform "None (no ...)" options across all insight dropdowns.
3. **Request & Controller Specs**:
   - [`spec/requests/current_teams/memories_request_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/requests/current_teams/memories_request_spec.rb):
     - **Regression**: Test clearing `memo` during edit (verifying validation error occurs and old memo is not retained).
     - **Regression**: Test detaching each insight type (picture, location, thought, weblink) by setting their ID to blank.
     - **Regression**: Test location creation with valid country code.
     - **Regression**: Test mutual exclusivity failure handling (422 response).
4. **System Specs**:
   - [`spec/system/memory_form_picture_upload_spec.rb`](file:///Users/andy/Dropbox/www/yournaling/spec/system/memory_form_picture_upload_spec.rb):
     - Full browser workflow: creating memory with picture upload, updating/replacing picture, attaching location with country code, thoughts, weblinks, and detaching each insight type.
5. **Full CI Suite**:
   - `bin/mcp_rake_ci`: Confirm 0 test failures, 0 RuboCop offenses, and clean DB Doctor checks.
