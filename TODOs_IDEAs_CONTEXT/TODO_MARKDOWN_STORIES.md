# Story Insight + Markdown editor & rendering (Marksmith / GFM)

Status: **in progress** (branch `markdown-story`). Supersedes `TODO_MARKDOWN_STORY.md`.
Consolidates the notes from the old `markdown-stories` branch + implementation plan.
Related: #18 (Markdown), [TODO_CHRONICLES.md](TODO_CHRONICLES.md) §2.2.

---

## 1. Goal

A first-class **`Story`** insight: like `Thought`, but for long-form prose written
in **Markdown (GFM)**, edited with the **Marksmith** editor, **stored as plain
Markdown text**, and **rendered to sanitized HTML on display**. Finish by making
`Story` attachable to **Chronicles** (not to `Memory`).

---

## 2. Decisions (refined from the old notes)

| Topic | Decision | Rationale |
|---|---|---|
| Model | `Story < ApplicationRecordForContentAndPosts`, `YID_CODE = "story"` | same lifecycle as every other insight |
| Columns | `team_id`, `name` (string, required — the headline), `content` (text, required — the Markdown source), `date` (date, optional), `visibility` (enum) | explicit `name` per the notes (no virtual `name` like `Thought`) |
| Length | `content` 20..16_384 chars (validated on the **Markdown source**) | matches the notes / `TODO_CHRONICLES` |
| `date` | **optional** (`Thought.date` is optional too; `Chronicle` needs it, insights don't) | deviates from the old note's "required"; keeps the quick-create drawer minimal |
| `visibility` default | **`draft`** (DB), like every sibling table | the old note said `:internal`, but that predates `ChangeDefaultVisibilityToDraft` (20260817195500) which set every content table to `draft`. Stay consistent. |
| Memory link | **none** — no `memories.story_id`, no `Story#memories` | the notes: "made available as ChronicleEntry (but not to Memory)" |
| Editor | **Marksmith** (`gem "marksmith", "~> 0.6"`), importmap-pinned | gem-based, Stimulus/ViewComponent stack fit; already chosen on the old branch |
| Renderer | **`commonmarker` (~> 2)** GFM + `Rails::Html::SafeListSanitizer`, wrapped in one `MarkdownRenderer` service | one renderer for editor preview *and* show pages; GFM; safe by default. Not redcarpet. |
| Storage | plain Markdown in `stories.content` — no ActionText/XML | Marksmith is only a `<textarea>` enhancement; the field value *is* Markdown ✅ |
| MVP scope | GFM (tables, strikethrough, task lists, autolinks, fenced code). **Raw HTML disabled.** Images/links: rendered if present in the Markdown, but Marksmith's upload/attachment UI is **off** in v1. | keeps the surface small; image upload → follow-up that routes through `Picture` / `ImageUploadConversionService` |
| Editor preview | Marksmith's built-in Write/Preview tabs. Side-by-side is a follow-up. | |

### Out of scope (post-MVP, see old notes)
`text-expander-element` (`:emoji:`, `@team`, `@@user`, `#hashtag`), custom
story/code themes, Mermaid, syntax highlighting, keyboard shortcuts, applying
Markdown to `Chronicle#notice` / `Thought#text` / `Memory#memo`.

---

## 3. Architecture — mirror `Thought`

`Thought` is the reference implementation for every layer. Files touched:

- **Model** `app/models/story.rb` (+ `Team has_many :stories`)
- **Migration** `db/migrate/*_create_stories.rb`
- **Renderer** `app/services/markdown_renderer.rb` + `app/helpers/markdown_helper.rb`
- **Styling** `app/assets/stylesheets/design/prose.css` (`.yui-prose`) + list it in
  `_design_head.html.slim` (`app_sheets`); the `spec/lib/design_head_spec.rb`
  guard derives from disk, no spec edit needed
- **Policy** `app/policies/story_policy.rb` → `InsightPolicy`
- **Routes** `current_team` `resources :stories`; `teams` module
  `resources :stories, only: %i[show]`; `admin` `resources :stories`
- **Controllers** `CurrentTeams::StoriesController`, `Teams::StoriesController`,
  `Admins::StoriesController`
- **Views** `app/views/{current_teams,teams,admins}/stories/*`
- **Editor wiring** `Gemfile`, `config/importmap.rb`, `config/initializers/marksmith.rb`,
  `app/javascript/controllers/index.js` (Marksmith controller), `config/routes.rb`
  (mount `Marksmith::Engine`)
- **Chronicle integration**
  - `ChronicleEntry::VALID_ENTRY_TYPES << "Story"`
  - `Chronicle`: `attr_accessor` list, `has_many :stories, through: :entries`
  - `ChronicleInsightAttacher::INSIGHT_PARAM_KEYS += %i[story_id story_text]`,
    `#attach_story`, `#find_entry_by_id` also checks `team.stories`
  - `InsightResolver#resolve_story`
  - `ChronicleAttachedEntriesFormComponent` — `when "Story"` branch
  - `InsightAttachmentManagerComponent` (+ `insight_manager_controller.js`) —
    Story create/select templates, `createStoryUrl`, chip icon 📖
  - `ChronicleEntryComponent` renders `…/stories/_story` (already generic)
  - `InsightDestroyModalComponent` — `when Story` in `destroy_path`, guard `memories`
- **Factory** `spec/factories/stories_factory.rb`
- **Specs** model, request (current_team + teams), policy, renderer, chronicle
  attacher/resolver, system (editor)

---

## 4. Rendering pipeline

```
stories.content (Markdown, plain text)
  └─ MarkdownRenderer.render(content)
       ├─ Commonmarker.to_html(content,
       │     options: { render: { unsafe: false, hardbreaks: false },
       │                 extension: { table: true, strikethrough: true,
       │                              tasklist: true, autolink: true, tagfilter: true } })
       └─ Rails::Html::SafeListSanitizer.new.sanitize(html, tags:…, attributes:…)
  └─ wrapped in <div class="yui-prose"> on show pages & Chronicle timeline
```

Same service feeds Marksmith's `/marksmith/previews` (via
`config/initializers/marksmith.rb` → `Marksmith.configure { |c| c.renderer = ... }`
or a `MarksmithController` renderer override) so preview == published output.

No rendered-HTML caching in v1 (render on show). Revisit with a `content_html`
column or fragment cache if profiling shows cost.

---

## 5. Implementation phases (TDD per AGENTS.md)

1. **Renderer** — `commonmarker`, `MarkdownRenderer`, helper, `prose.css`. Specs:
   GFM features + XSS (`<script>`, `javascript:` href, `onerror=`, raw `<iframe>`).
2. **Model + migration** — `Story`, `Team.has_many`, factory. Model spec
   (validations, length bounds, `multisearchable against: %i[name content]`,
   `attr_readonly :team_id`, visibility states, parent-visibility constraint).
3. **Workspace CRUD** — routes + `CurrentTeams::StoriesController` (mirror
   Thoughts incl. JSON `create` → `{ id:, text: name, type: "story" }`, destroy
   guard on `chronicle_entries`), views (`_form` uses `form.marksmith :content`),
   `StoryPolicy`. Request spec.
4. **Public + admin** — `Teams::StoriesController` (published-only),
   `Admins::StoriesController` + views. Request spec for the public show.
5. **Show rendering** — `_story.html.slim` (`.yui-prose = markdown(story.content)`),
   `show`/`index`/`new`/`edit` templates for all three scopes.
6. **Marksmith wiring** — gem, importmap pins, engine mount (behind auth),
   initializer, controller registration. System spec: type `**bold**`, preview
   shows `<strong>`, submit persists raw Markdown to the column.
7. **Chronicle integration** — entry type, associations, attacher, resolver,
   form components, JS manager, entry rendering. Attacher/resolver/request specs
   + a system spec adding a Story to a Chronicle.
8. **Docs** — update `TODO_CHRONICLES.md` (Story = done), `ERD.mmd`,
   `ROADMAP.markdown`; delete `TODO_MARKDOWN_STORY.md`.

---

## 6. Caveats, risks, dependencies

- **Marksmith + importmap**: the gem's docs lead with esbuild; importmap needs
  its JS deps pinned individually (`@github/markdown-toolbar-element` etc.).
  Fallback: pin from `cdn.jsdelivr.net`. Main schedule risk.
- **`/marksmith/previews`**: echoes rendered user input — mount behind
  authentication and route through the shared sanitizing `MarkdownRenderer`.
- **Sanitisation**: keep the sanitizer pass even with `unsafe: false`; regression
  tests for `javascript:`/`data:` URLs, `on*=` handlers, `<style>`/`<iframe>`.
- **Length limit** is on the Markdown source (16_384), not the rendered HTML.
- **Search** indexes raw Markdown (syntax noise) — acceptable for v1.
- **Quick-create drawer** in the Chronicle form uses a plain `<textarea>` for the
  new-Story path (no full Marksmith editor in the cloned `<template>`); the rich
  editor lives on the dedicated Story new/edit pages. Acceptable MVP trade-off.
- **Visibility default** `draft` (not `internal`) — see §2.
- **No Memory association** — `InsightDestroyModalComponent#memories` and
  `VisibilityConstrainedByParents` must tolerate a `Story` without `#memories`.
- Loosely related to #38 (forms) and #39 (`StoryPolicy#read?` should become
  team-scoped for non-published, same as the other insights).
