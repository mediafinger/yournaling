# Search Improvements Tasks

The work was half-done, but then interrupted. Please check what is still open and continue.

## Search Improvements - Proposed Changes (Implementation Plan)

Seven improvements to the search feature, planned as TDD — specs written first, then implementation.

### 1. Fix N+1 queries — use `includes(:searchable)` and `result.searchable`

The polymorphic `belongs_to :searchable` on `PgSearch::Document` works correctly with the string-based YIDs (confirmed via `rails runner`). We can replace `ApplicationRecordYidEnabled.fynd(result.searchable_id)` with eager-loaded `result.searchable`.

#### [MODIFY] [searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/searches_controller.rb)
- Add `.includes(:searchable)` to the query chain

#### [MODIFY] [current_teams/searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/searches_controller.rb)
- Add `.includes(:searchable)` to the query chain

#### [MODIFY] [search_results_component.rb](file:///Users/andy/Dropbox/www/yournaling/app/view_components/search_results_component.rb)
- Replace `ApplicationRecordYidEnabled.fynd(result.searchable_id)` with `result.searchable`
- Use `result.searchable.updated_at` instead of `result.updated_at` (fixes point 6 — shows the record's timestamp, not the search index timestamp)

---

### 2. Reject invalid `klass_name` values

Currently, an unknown `klass_name` (e.g. `"Foo"`) silently runs an **unscoped** search across all types. Instead, treat it like a missing klass_name and skip the search.

#### [MODIFY] [searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/searches_controller.rb)
- In `new`: add `|| !SEARCHABLE_KLASSES.include?(@klass_name)` to the early-return guard
- In `create`: add the same check before redirecting to results

#### [MODIFY] [current_teams/searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/searches_controller.rb)
- Same changes in `new` and `create`

---

### 3. Display `content` snippet in search results

Resolve the existing `TODO` on [line 19](file:///Users/andy/Dropbox/www/yournaling/app/view_components/search_results_component.rb#L19). Show a truncated excerpt from `result.content` alongside each link.

#### [MODIFY] [search_results_component.rb](file:///Users/andy/Dropbox/www/yournaling/app/view_components/search_results_component.rb)
- Add a `span` or `small` element rendering `result.content.truncate(120)` after each link
- Remove the TODO comment

---

### 4. Gracefully handle deleted records (stale index entries)

When `result.searchable` returns `nil` (record was deleted but `pg_search_documents` row lingers), silently skip the result. This already happens via the `return if record.blank?` guard, but we should also log a warning so stale entries are discoverable.

#### [MODIFY] [search_results_component.rb](file:///Users/andy/Dropbox/www/yournaling/app/view_components/search_results_component.rb)
- Add `Rails.logger.warn("Stale search index entry: #{result.searchable_type}##{result.searchable_id}")` when `result.searchable.nil?`

---

### 5. Extract shared search logic into a concern

Both controllers duplicate: `SEARCHABLE_KLASSES`, `query_params`, the validation guard, and the `PgSearch.multisearch(...)` query pattern.

#### [NEW] [searchable.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/searchable.rb)
- Extract `query_params`, the validation logic (min length, klass_name inclusion), and the `perform_search` method
- Each controller defines its own `SEARCHABLE_KLASSES` and passes additional scope (e.g. `team_id:`)

#### [MODIFY] [searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/searches_controller.rb)
- `include Searchable`, remove duplicated methods, call shared `perform_search`

#### [MODIFY] [current_teams/searches_controller.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/current_teams/searches_controller.rb)
- `include Searchable`, remove duplicated methods, call shared `perform_search` with `team_id:` scope

---

### 6. Unify the two form partials into a `SearchFormComponent`

> [!IMPORTANT]
> This is the most opinionated change. The two form partials differ only in `url`, `klass_options`, and `default_klass`. A component centralizes this, but if you prefer keeping them as partials, we can skip this.

#### [NEW] [search_form_component.rb](file:///Users/andy/Dropbox/www/yournaling/app/view_components/search_form_component.rb)
- Accepts `url:`, `klass_options:`, `default_klass:`, `query:`, `klass_name:`, `form_legend:`
- Renders the form with Stimulus bindings

#### [DELETE] [searches/_form.html.slim](file:///Users/andy/Dropbox/www/yournaling/app/views/searches/_form.html.slim)
#### [DELETE] [current_teams/searches/_form.html.slim](file:///Users/andy/Dropbox/www/yournaling/app/views/current_teams/searches/_form.html.slim)

#### [MODIFY] [searches/new.html.slim](file:///Users/andy/Dropbox/www/yournaling/app/views/searches/new.html.slim)
- Replace `render partial: "form"` with `render SearchFormComponent.new(...)`

#### [MODIFY] [current_teams/searches/new.html.slim](file:///Users/andy/Dropbox/www/yournaling/app/views/current_teams/searches/new.html.slim)
- Replace `render partial: "form"` with `render SearchFormComponent.new(...)`

---

## Open Questions

> [!IMPORTANT]
> **Point 6 (SearchFormComponent):** Do you want to replace the two form partials with a ViewComponent, or keep them as partials? Both work; the component is more consistent with the rest of the codebase (you already have `SearchResultsComponent`).

> [!NOTE]
> **Point 4 (stale entry logging):** Is `Rails.logger.warn` sufficient, or would you prefer something more active like deleting the stale `PgSearch::Document` row on the spot?

## Verification Plan

### Automated Tests
```bash
source /opt/homebrew/share/chruby/chruby.sh && chruby 4.0.5 && rake ci
```

### Specs written first (TDD)
All new specs are written before implementation. They will initially fail, then pass after each implementation step.


---

## Phase 1: Write specs (TDD — all should fail initially)

- [x] Update `search_results_component_spec.rb` — content snippet, stale entry warning, record's `updated_at`
- [x] Update `searches_spec.rb` — reject invalid `klass_name`
- [x] Update `current_teams/searches_spec.rb` — reject invalid `klass_name`
- [x] Create `search_form_component_spec.rb` — new ViewComponent

### TDD status: 6 new specs failing as expected, 1 spec (SearchFormComponent) can't load (NameError)

Failing specs:
- `search_results_component_spec.rb` — content snippet not displayed, stale entry warning not logged
- `searches_spec.rb` — invalid klass_name not rejected (GET + POST)
- `current_teams/searches_spec.rb` — invalid klass_name not rejected (GET + POST)
- `search_form_component_spec.rb` — class doesn't exist yet (NameError)

## Phase 2: Implement

- [x] Create `Searchable` concern (extract shared controller logic)
- [x] Refactor `SearchesController` to use `Searchable` concern
- [x] Refactor `CurrentTeams::SearchesController` to use `Searchable` concern
- [x] Update `SearchResultsComponent` — eager-loaded `.searchable`, content snippet, stale entry log, record `updated_at`
- [x] Create `SearchFormComponent` — replace both form partials
- [x] Delete old form partials, update views to use `SearchFormComponent`

## Phase 3: Verify

- [x] Run `rake ci` — all green (615 examples, 0 failures)

