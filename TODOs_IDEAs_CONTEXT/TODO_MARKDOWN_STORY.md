# TODO — `Story` Insight + Markdown Editing & Rendering (Marksmith / GFM)

Status: **planned**. Created 2026-09-03.
Owner: —
Related: #18 (Enable Markdown inputs and display), [TODO_CHRONICLES.md](TODO_CHRONICLES.md) §2.2,
[REFACTOR_INSIGHTS_AND_POSTS.markdown](REFACTOR_INSIGHTS_AND_POSTS.markdown),
[TOP_10_NEXT_STEPS.markdown](TOP_10_NEXT_STEPS.markdown) §1.

---

## 1. Goal

Introduce a first‑class **`Story`** insight: like `Thought`, but for long‑form prose
(target **up to 16,384 characters**) written in **Markdown (GitHub Flavored Markdown)**.

Requirements:

1. New `Story < ApplicationRecordForContentAndPosts` model, sibling of `Thought` / `Weblink`.
2. A **Markdown editor** (Marksmith — <https://github.com/avo-hq/marksmith>) on the
   Story create & update forms.
3. **Render** the stored Markdown to clean, safe HTML that looks nice on show pages
   and inside Chronicles. GFM support (tables, strikethrough, task lists,
   autolinks, fenced code).
4. **Store content as plain Markdown text** in a normal `text` column — no ActionText,
   no XML, no serialized blob. (This is fully supported: Marksmith is only a
   textarea enhancement; it neither requires nor produces ActionText.)
5. Finish by wiring `Story` into **Chronicles** as an attachable entry type,
   exactly like `Thought`.

---

## 2. Findings — current state of the codebase

### 2.1 "Prior Marksmith work"
No dedicated Marksmith branch or code exists. What likely created that impression:

- **`redcarpet 3.6.1` is already in `Gemfile.lock`** — but only as a *transitive
  dependency of `lookbook`*, not a direct dependency and not wired to any app code.
- `Yui::FieldComponent` / `app/views/example/show.html.slim` already carry the
  copy *"Markdown is supported."* as a hint — aspirational, not yet functional.
- `Chronicle#notice` and docs describe Markdown narrative text, but `notice` is
  currently rendered as plain text.

Conclusion: we are starting Marksmith integration from scratch. There is **no
Markdown rendering anywhere in the app today.**

### 2.2 Relevant existing architecture (mirror this)

| Concern                              | Reference implementation                                                                                                                                                                                                                                                                                                                       |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Insight model                        | [app/models/thought.rb](app/models/thought.rb) — `ApplicationRecordForContentAndPosts`, `YID_CODE`, `VisibilityConstrainedByParents`, `multisearchable`, `attr_readonly :team_id`, `normalizes`, virtual `name` column                                                                                                                         |
| Insight controller                   | [app/controllers/current_teams/thoughts_controller.rb](app/controllers/current_teams/thoughts_controller.rb) — `skip_before_action :authenticate, only: %i[index show]`, `create_with_event` / `update_with_event`, JSON responses used by the Chronicle attacher                                                                              |
| Public controller                    | `app/controllers/teams/thoughts_controller.rb` + nested route                                                                                                                                                                                                                                                                                  |
| Admin controller                     | `app/controllers/admins/thoughts_controller.rb`                                                                                                                                                                                                                                                                                                |
| Policy                               | [app/policies/thought_policy.rb](app/policies/thought_policy.rb) → `InsightPolicy`                                                                                                                                                                                                                                                             |
| Views                                | `app/views/current_teams/thoughts/{_form,_thought,show,new,edit,index}.html.slim` (Slim + `YuiFormBuilder` + `Yui::*` components)                                                                                                                                                                                                              |
| Routes                               | `config/routes.rb`: `current_team` namespace `resources :thoughts`; `teams` module `resources :thoughts, only: %i[show]`; top‑level nested `resources :thoughts, only: %i[show]`                                                                                                                                                               |
| Chronicle wiring                     | `ChronicleEntry::VALID_ENTRY_TYPES`, `Chronicle` `has_many :thoughts, through: :entries`, `accepts_nested_attributes_for :entries`                                                                                                                                                                                                             |
| Insight creation from Chronicle form | [app/services/insight_resolver.rb](app/services/insight_resolver.rb) `#resolve_thought`, [app/services/chronicle_insight_attacher.rb](app/services/chronicle_insight_attacher.rb) `INSIGHT_PARAM_KEYS` (`thought_id thought_text`), [app/controllers/concerns/chronicle_form_handling.rb](app/controllers/concerns/chronicle_form_handling.rb) |
| Chronicle form UI                    | `ChronicleAttachedEntriesFormComponent`, `InsightAttachmentManagerComponent`, JS `insight_select_controller.js` / `insight_manager_controller.js`                                                                                                                                                                                              |
| Visibility cascade                   | `Chronicle#cascade_visibility_to_entries`, `ChronicleEntry#align_entry_visibility` — generic, needs no per‑type change                                                                                                                                                                                                                         |
| Assets                               | Propshaft + **importmap-rails** (no bundler). Stimulus via `stimulus-loading`, controllers auto‑pinned from `app/javascript/controllers`.                                                                                                                                                                                                      |
| Search                               | `pg_search` `multisearchable`; virtual `name` column pattern (`substring(text,0,60) || '...'`)                                                                                                                                                                                                                                                 |

---

## 3. Technology decisions

### 3.1 Editor: Marksmith
- Rails engine gem; ships a Stimulus controller + a GitHub‑style toolbar
  (`@github/markdown-toolbar-element`) wrapping a plain `<textarea>`.
- Provides a `marksmith` form‑builder helper: `form.marksmith :body`.
- Live preview: the editor POSTs the textarea content to a mounted engine route
  (`/marksmith/previews`) which returns rendered HTML.
- **The textarea value is plain Markdown** → saved to our `text` column verbatim. ✅

### 3.2 Renderer: `commonmarker` (GFM) — one renderer for editor preview *and* show pages
- Add `gem "commonmarker"` (Rust `comrak`, actively maintained, spec‑compliant GFM).
- Configure Marksmith to use it for previews (Marksmith renderer is configurable;
  default tries `commonmarker`, then `redcarpet`, then `github/markup`).
- Build our own `MarkdownRenderer` service so show‑page rendering and editor
  preview are byte‑for‑byte identical.
- Options: enable extensions `table`, `strikethrough`, `tasklist`, `autolink`,
  `tagfilter`; **`unsafe: false`** (no raw HTML passthrough); `hardbreaks: false`.
- Defense in depth: pass output through `Rails::Html::SafeListSanitizer` (or
  `sanitize` helper) with an explicit allow‑list even though `unsafe: false`.
- Do **not** use `redcarpet` for app rendering (keep it only as lookbook's
  transitive dep). One renderer, GFM, safe by default.

### 3.3 Storage
- Column: `stories.text` — `text`, `null: false`. Plain Markdown source.
- No caching of rendered HTML in v1 (render on show). If profiling shows cost,
  add a `body_html` cache column or `Rails.cache` fragment keyed on
  `cache_key_with_version` — deferred.

---

## 4. Data model

```
stories
  id           :string  (YID, id: :string like siblings)
  team_id      :string  not null, index [team_id, date]
  text         :text    not null            # plain GFM markdown, 20..16_384 chars
  date         :date
  name         :string  not null
  visibility   :enum content_visibility, default 'draft', not null
  created_at / updated_at
```

`app/models/story.rb` (mirror `Thought`):

```ruby
class Story < ApplicationRecordForContentAndPosts
  include VisibilityConstrainedByParents

  YID_CODE = "story"

  MIN_LENGTH = 20
  MAX_LENGTH = 16_384

  belongs_to :team, inverse_of: :stories
  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries

  multisearchable(
    against: %i[name text date],
    additional_attributes: ->(story) { { team_id: story.team_id } }
  )

  attr_readonly :team_id
  
  normalizes :name, with: ->(name) { name.strip }
  normalizes :text, with: ->(text) { text.strip }

  validates :text, presence: true, length: { in: MIN_LENGTH..MAX_LENGTH }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  def to_html = MarkdownRenderer.render(text)
end
```

---

## 5. Implementation plan (phased, TDD per AGENTS.md)

> Each phase: plan → failing specs → implement → `bin/mcp_rubocop -A <files>` →
> `bin/mcp_rake_ci` green → commit. Small PRs.

### Phase 0 — Renderer foundation (no UI)
1. `Gemfile`: add `gem "commonmarker", "~> 2.0"`; `bundle install`.
2. `app/services/markdown_renderer.rb`:
   - `MarkdownRenderer.render(String) -> ActiveSupport::SafeBuffer`
   - commonmarker with the extension/option set from §3.2, then sanitizer pass.
   - `nil`/blank → `"".html_safe`.
3. `app/helpers/markdown_helper.rb`: `markdown(text)` → `MarkdownRenderer.render`.
4. `.yui-prose` stylesheet in `app/assets/stylesheets/design/` (headings, lists,
   tables, `code`/`pre`, blockquote, links) — scoped wrapper class for rendered
   output. Register per existing design CSS conventions.
5. Specs `spec/services/markdown_renderer_spec.rb`:
   - GFM: table, `~~strike~~`, `- [ ]` task list, bare‑URL autolink, fenced code.
   - **Security**: `<script>`, `<img onerror=>`, `[x](javascript:alert(1))`,
     raw `<iframe>` → all neutralised.
   - Idempotent / blank input.

### Phase 1 — `Story` model + workspace CRUD
1. Migration `create_stories` (id: :string) + `stories`  `name` column +
   enum default
2. `Story` model (§4) + `spec/models/story_spec.rb` (validations, length bounds,
   `multisearchable`, `attr_readonly`, visibility states, `to_html`).
3. `StoryPolicy < InsightPolicy` (empty, like `ThoughtPolicy`) + policy spec.
4. Routes:
   - `current_team` namespace: `resources :stories`
   - `teams` module: `resources :stories, only: %i[show]`
   - top‑level `resources :teams do ... resources :stories, only: %i[show]`
5. Controllers mirroring Thoughts:
   - `CurrentTeams::StoriesController` — full CRUD, `create_with_event` /
     `update_with_event`, `skip_before_action :authenticate, only: %i[index show]`,
     JSON `create` response `{ id:, text: text.truncate(60), type: "story" }`
     (consumed by the Chronicle attacher), `destroy` guard when referenced by `chronicle_entries`.
   - `Teams::StoriesController` (public `show`, visibility‑gated).
   - `Admins::StoriesController` + Avo resource.
   - `story_params = params.expect(story: %i[text date])`.
6. Request specs `spec/requests/current_teams/stories_spec.rb` +
   `spec/requests/teams/stories_spec.rb` (guest can see published, cannot see
   draft; member CRUD; non‑member denied).

### Phase 2 — Marksmith editor on the forms
1. `Gemfile`: `gem "marksmith"`; `bundle install`. Run its install generator if
   present, otherwise wire manually:
   - Mount engine in `config/routes.rb`: `mount Marksmith::Engine => "/marksmith"`
     **inside an authenticated context** (preview endpoint should require a
     logged‑in user — put it above the `*path` catch‑all, guard with the same
     `authenticate` before_action mechanism or a constraint).
   - `config/importmap.rb`: pin `marksmith` and its JS deps
     (`@github/markdown-toolbar-element`, and any `tributejs` / textarea helpers
     Marksmith lists for importmap users — follow the gem's importmap section).
   - Register the Marksmith Stimulus controller in
     `app/javascript/controllers/index.js` (or `pin_all_from` if the gem exposes
     controllers on the load path).
   - Include Marksmith CSS via `stylesheet_link_tag` / Propshaft path, plus our
     `.yui-prose` for the preview pane.
2. Configure Marksmith renderer → `MarkdownRenderer` (initializer
   `config/initializers/marksmith.rb`), so preview == show output.
3. `app/views/current_teams/stories/_form.html.slim`:
   ```slim
   = render Yui::CardComponent.new do
     = form_with(model: [:current_team, story], builder: YuiFormBuilder, html: { class: "yui-stack" }) do |form|
       = render Yui::HeadlineComponent.new(form_legend, level: 3)
       = render partial: "shared_partials/form_validation_errors", locals: { record: story }
       = form.marksmith :text, label: "Story", height: 400
       = form.date_field :date
       = form.submit
   ```
   - If `YuiFormBuilder` doesn't inherit Marksmith's helper, add a
     `marksmith` method to `app/form_builders/yui_form_builder.rb` delegating to
     `@template.marksmith_tag` with Yui field markup/labels.
4. `new` / `edit` templates (thin, like Thoughts).
5. Decide on Marksmith's **image upload** feature:
   - v1: **disable attachments** (`attachable: false` or equivalent) to avoid a
     parallel upload path competing with `Picture`. Document as follow‑up to wire
     uploads into `ImageUploadConversionService` + `Picture`.
6. System spec `spec/system/stories_spec.rb`: toolbar renders, typing `**bold**`
   + clicking Preview shows `<strong>`, form submits, value persists as raw
   markdown (assert DB column equals typed source).

### Phase 3 — Rendering on show pages
1. `app/views/current_teams/stories/_story.html.slim` — mirror `_thought.html.slim`
   but render `div.yui-prose = story.to_html` inside the card
   (`Yui::CardComponent` + `ManageHeaderComponent`); a `hide_actions` variant for
   embedding.
2. `show.html.slim` (workspace) + `app/views/teams/stories/show.html.slim` (public).
3. `index.html.slim` — card list; show truncated rendered HTML or first paragraph
   (`story.name`).
4. Request specs assert rendered HTML present & sanitised; N+1 check on index.

### Phase 4 — Chronicle integration
1. `ChronicleEntry::VALID_ENTRY_TYPES` += `"Story"`.
2. `Chronicle`:
   - `attr_accessor` list — extend `ChronicleInsightAttacher::INSIGHT_PARAM_KEYS`.
   - `has_many :stories, -> { reorder("chronicle_entries.position ASC") }, through: :entries, source: :entry, source_type: "Story"`.
3. `ChronicleInsightAttacher::INSIGHT_PARAM_KEYS` += `story_id story_text`;
   add `attach_story` + call in `#attach`.
4. `InsightResolver#resolve_story(story_id:, story_text:)` — mirror
   `#resolve_thought` (create via `Story.create_with_event`, else find by id).
5. `ChronicleFormHandling#permit_chronicle_params` — keys come from
   `INSIGHT_PARAM_KEYS`, so automatic; double‑check nested `entries_attributes`.
6. UI:
   - `ChronicleAttachedEntriesFormComponent` — add a Story picker (existing
     stories `<select>`) + a "new story" Marksmith textarea, following the
     `thought` block and its `insight_select_controller` targets.
   - `InsightAttachmentManagerComponent` — add Story to the add‑entry menu.
   - `ChronicleEntryComponent` / `_chronicle.html.slim` (current_team, teams,
     admins) — render a `Story` entry via the `.yui-prose` partial.
7. `Chronicle.preload_attachments` / `includes(entries: :entry)` already covers
   Story (polymorphic). No picture‑style attachment preload needed.
8. Specs:
   - `spec/services/chronicle_insight_attacher_spec.rb` — attach existing Story,
     create new Story from `story_text`.
   - `spec/services/insight_resolver_spec.rb` — `resolve_story` both paths +
     error merge (`merge_errors_and_raise!(story, :story_text)`).
   - `spec/requests/current_teams/chronicles_spec.rb` — create/update Chronicle
     with a new inline Story; visibility cascade to the Story entry.
   - `spec/system/chronicles_spec.rb` — add Story via the form, reorder, render.

### Phase 5 — Docs & polish
1. Update [TODO_CHRONICLES.md](TODO_CHRONICLES.md) §2.2 / tables: Story = **done**.
2. Update `ERD.mmd`, `REFACTOR_INSIGHTS_AND_POSTS.markdown`,
   `TOP_10_NEXT_STEPS.markdown`.
3. Close / update issue #18 (Markdown) — note GFM via commonmarker, editor via
   Marksmith, applies to `Story` (and later `Chronicle#notice`, `Weblink`/
   `Location#description`).
4. Follow‑up issues: (a) Marksmith image uploads → `Picture`; (b) apply Markdown
   rendering to `Chronicle#notice` and insight `description` fields;
   (c) rendered‑HTML caching if needed.

---

## 6. Effort & value

|            |                                                                                                                                                                       |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Effort** | **M–L** (~1–1.5 weeks). Model/CRUD/policy is a well‑trodden copy of `Thought` (S). The unknowns are Marksmith + importmap asset wiring and the Chronicle form UI (M). |
| **Value**  | **4/5** — unlocks the core "travel journal / long-form story" product promise (see TOP_10_NEXT_STEPS #1) and the first real Markdown surface in the app.              |

---

## 7. Caveats, risks & dependencies

- **Marksmith + importmap**: Marksmith's docs lead with bundler (esbuild). The
  importmap path needs its JS deps pinned individually and may lag. Budget time
  to verify the toolbar + preview work under Propshaft/importmap; fallback is
  pinning from `cdn.jsdelivr.net` in `importmap.rb`. This is the main schedule risk.
- **Preview endpoint auth**: `/marksmith/previews` echoes rendered user input.
  Mount behind authentication and rely on the shared sanitising `MarkdownRenderer`
  so preview can't become an XSS/SSRF vector.
- **Sanitisation**: even with `commonmarker unsafe: false`, run the sanitizer
  pass. Add regression tests for `javascript:` links, `on*=` handlers, raw
  `<iframe>`/`<style>`, and data‑URI images.
- **Character limit**: validate on the **Markdown source** length (16,384). Note
  that rendered HTML is larger; the limit is on source only.
- **Search**: `multisearchable against: %i[text date]` indexes raw Markdown
  (syntax noise). Acceptable for v1; a follow‑up could index stripped plain text.
- **`Story` vs `Chronicle#notice` overlap**: keep `notice` as the short built‑in
  intro; `Story` is the standalone/reusable long form. Don't merge them now.
- **Visibility**: `VisibilityConstrainedByParents` + the generic cascade in
  `Chronicle`/`ChronicleEntry` already handle `Story` — no new visibility code,
  but add a cascade spec.
- **Dependencies**: none blocking. Interacts with #38 (forms) — the Marksmith
  field should use the same `Yui` field wrapper conventions. Loosely related to
  #39 (a `StoryPolicy#read?` must be team‑scoped for non‑published, same as other
  insights).
- **`redcarpet`**: leave as lookbook's transitive dep; do not adopt for app
  rendering. One renderer (`commonmarker`) only.
