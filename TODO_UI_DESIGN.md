# TODO UI Design

Status: **planning** · Owner: andy · Created 2026-08-31

This document is the plan for moving Yournaling's UI from Pico.css to the
bespoke **"Warm Editorial"** design language that already lives under
`/example`. It also records, at the end, the alternative we are *not* taking
(switching to Tailwind CSS) with its trade-offs, so the decision is traceable.

---

## 1. Where we are today

### Styling stack

| Piece          | Detail                                                                                                                                                                                                                                 |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Asset pipeline | **Propshaft** (no Sprockets, no `cssbundling-rails`)                                                                                                                                                                                   |
| CSS framework  | **Pico.css**, loaded per layout — `unpkg` CDN in production, a checked-in copy in development. Three colour themes: `pico.amber` (public / user), `pico.green` (team workspace), `pico.blue` (admin).                                  |
| Custom CSS     | `general.css`, `buttons.css`, `navbar.css`, `card.css`, `lightbox.css`, `admin.css` + two reset files, linked by logical name; each is its own request. Heavy use of `var(--pico-*)`.                                                  |
| Sass           | `dartsass-rails` is in the Gemfile and `Procfile.dev` runs `dartsass:watch`, **but the setup is inert** — `application.scss` is a one-line comment, `app/assets/builds/application.css` is empty, and no layout links it. Dead weight. |
| JS             | **importmap only**, no bundler. Stimulus controllers `dropdown`, `modal`, `tabs`, `sortable`, plus the lightbox, assume Pico markup (`details.dropdown`, `dialog > article`).                                                          |
| CSP            | Entirely commented out, so the CDN link needs no allow-listing (yet).                                                                                                                                                                  |
| Templates      | **~178 Slim templates; only ~9 use `class=` at all.** Everything else relies on Pico styling bare `article` / `nav` / `table` / `form` / `input` / `button` / `blockquote` / `dialog`.                                                 |
| Components     | ~32 app-level ViewComponents (nav, headers, modals, dropdowns, lightbox, empty-state, search…) that emit Pico-idiomatic markup.                                                                                                        |

### The design language (`/example`)

Committed in `6bdcc9a` ("Draft new UI design and show under `/example`"):

- **`app/assets/stylesheets/example.css`** — ~1,430 lines, self-contained. Layers:
  tokens (`--ex-*`, light + `prefers-color-scheme: dark`), scoped base styles,
  layout utilities (`.ex-container`, `.ex-stack`, `.ex-cluster`, `.ex-grid`),
  components (`.ex-btn`, `.ex-card`, `.ex-field`, `.ex-badge`, `.ex-callout`,
  `.ex-input`, `.ex-dropdown`, …), composed records (`.ex-memory-card`,
  `.ex-chronicle-card`), showcase chrome.
  - **Scoped, not global**: everything hangs off `.ex-body` *or* `.ex-scope`.
    It sets **no global reset and no bare-element styles**, so it can be dropped
    onto a subtree of an existing page without fighting Pico.
  - Accessibility bar is already good: `:focus-visible` ring, `prefers-reduced-motion`,
    `::selection`, ARIA-friendly component APIs.
- **~28 `Example::*` ViewComponents** — `ButtonComponent`, `CardComponent` (slots),
  `FieldComponent`, `BadgeComponent`, `TagComponent`, `CalloutComponent`,
  `BlockquoteComponent`, `HeadlineComponent`, `IconComponent` (curated inline SVG set),
  `LinkComponent`, `AvatarComponent`, `FigureComponent`, `ChoiceComponent`,
  `MemoryCardComponent`, `ChronicleCardComponent`, `ProseComponent`, plus showcase-only
  helpers (`SectionComponent`, `SpecimenComponent`, `SwatchComponent`).
  - `Example::BaseComponent` inherits **`ViewComponent::Base` directly, not
    `ApplicationComponent`** — no auth, no policies, no app helpers. Pure
    presentational components. `ex_class(...)` and `ex_token(...)` helpers keep
    variant handling safe.
- **`/example`** — a 298-line showcase page with its own `layouts/example`
  (loads Google Fonts + `example.css` only), its own controller
  (`skip_before_action :authenticate`), routed as `example_path`.
- Fonts: **Fraunces** (display serif) + **Inter** (UI), currently pulled from
  Google Fonts **only in `layouts/example`**.

---

## 2. Chosen direction

**Build our own ViewComponents. No Tailwind. No DaisyUI / Flowbite / Preline /
any third-party component or utility library.**

Rationale:

- The identity is a product feature. Yournaling wants a calm, distinct editorial
  voice; every Tailwind kit makes apps look interchangeable.
- We already have the infrastructure (ViewComponent is used heavily) **and ~80%
  of the component vocabulary is built and reviewed**.
- Zero new runtime dependencies suits a Hotwire + importmap + Propshaft app.
  `example.css` is served directly by Propshaft — **no build step, no Node, no
  watcher, no CI asset step.**
- A token-driven ViewComponent system gives us the thing utility classes cannot:
  a visual change is one edit in one place, not a find-and-replace across
  hundreds of templates (see §8).

Third-party libraries were considered and rejected:

| Option                              | Why not                                                                                                                                                                                                                                  |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **DaisyUI**                         | CSS-only (Turbo-friendly, no JS to re-init) and easy to *theme*, but its rounded "SaaS" aesthetic is the opposite of Warm Editorial; re-skinning it to match = the work we've already done. Best when you have *no* system. We have one. |
| **Flowbite / Preline / Franken UI** | Ship their own vanilla JS that must be re-initialised on every Turbo navigation / frame render — a recurring papercut. Heavier. "Copy the markup" rather than semantic classes.                                                          |
| **Tailwind Plus (ex-Tailwind UI)**  | High quality, no runtime, but paid and React-flavoured; still needs porting to Slim/ViewComponent. Keep as a *reference* for focus states / ARIA wiring only.                                                                            |
| **RubyUI / Phlex component kits**   | Phlex-based; we're on ViewComponent + Slim. Mismatch.                                                                                                                                                                                    |

The full Tailwind alternative is documented in **§9** for completeness.

---

## 3. Do we still need Pico.css?

**No — Pico is transitional scaffolding and the end state removes it entirely.**

Its only value was styling ~167 classless templates for free. Once the
`Example::*` components cover the vocabulary, Pico is pure cost: a second reset,
an external CDN dependency, three theme stylesheets, and a pile of `!important`
overrides in `navbar.css` fighting it.

### Why they can coexist during the migration

`example.css` is **scoped** (`.ex-scope` / `.ex-body`) and defines **no global
reset or bare-element rules**. Pico's `--pico-*` variables and the `--ex-*`
tokens do not collide. So we can:

1. Wrap a layout's `<main>` (or any subtree) in `.ex-scope` and it renders in the
   new design while the surrounding chrome stays on Pico.
2. Migrate view by view inside that scope.
3. Once every template a layout renders is converted **and** that layout's nav /
   header / flash components are converted, drop the `pico.<colour>` link from
   that layout.
4. When the last layout is done, delete Pico and the custom `--pico-*` CSS.

### Interim rules

- **Never load Pico and `example.css` as competing full-page systems.** Scope
  `example.css` to main content; leave Pico owning the chrome until the nav
  components are ported (Phase 2).
- The three per-area accent colours (amber / green / blue) carry over as an
  `--ex-accent` override per layout — add a `data-area` attribute or body class
  and redefine `--ex-accent*` for `[data-area="team"]` / `[data-area="admin"]`
  in `example.css`. Default stays the terracotta.
- Keep `data-turbo-track: "reload"` on the stylesheet tag.

### Asset-handling changes for this path (minimal)

- **Remove `dartsass-rails`**, the dead `application.scss`, the empty
  `app/assets/builds/application.css`, and the `css:` line in `Procfile.dev`.
  Nothing replaces them — Propshaft serves `example.css` directly.
- **Self-host Fraunces + Inter** as `woff2` in `app/assets/fonts/` with
  `@font-face` in `example.css` (Propshaft fingerprints them) in Phase 0 to drop
  the Google CDN dependency immediately and simplify CSP.
- **Retire the `example.css` filename** by splitting it into
  `app/assets/stylesheets/design/` in Phase 1 (see §4 → *CSS file organisation*)
  — done alongside the `Yui::` rename, so "the example" name disappears in the
  same pass.
- **CSP**: when re-enabled (Phase 6), no external style/script host is needed if
  fonts are self-hosted. The `csp_meta_tag` is already in the layouts.
- **CI / tests**: no runtime build artefact. `rake ci` gains one thing — the
  Prettier + Stylelint `css` step (§4) with an `actions/setup-node` + `npm ci`
  step in CI; still no asset compilation. (Contrast with §9.)

---

## 4. Preprocessor, linting & formatting

Three decisions: **no Sass/SCSS** (author plain CSS); **split the stylesheet by
concern, ordered with `@layer`**; and **add Prettier + Stylelint to `rake ci`**.

### Preprocessor: why we stay on plain CSS (no Sass/SCSS)

**Decision: no Sass/SCSS. `example.css` stays plain CSS, authored with native
CSS nesting where it aids readability.**

The inert `dartsass-rails` setup (see §1) tempts a "reactivate it properly"
move. We won't. Modern CSS has absorbed almost everything Sass existed to
provide, and adopting Sass would re-introduce exactly the build step that §2 and
§3 are built around *not* having.

### What Sass would give us — and the native-CSS equivalent

| Sass feature                                           | Our situation                                                                                                                                                                                                                                      |
|--------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `$variables`                                           | We use CSS custom properties (`--ex-*`). Strictly **better** here: runtime, cascade-aware, devtools-inspectable — and the reason the `prefers-color-scheme` dark-mode token swap works at all. Sass variables are compile-time and cannot do that. |
| Nesting, `&`                                           | **Native CSS nesting** ships in every browser we support (Baseline 2023). Adopt freely, zero tooling.                                                                                                                                              |
| `darken()` / `lighten()` / `mix()`                     | **`color-mix()`** (already used in `example.css` for the callout borders), relative colour syntax `hsl(from var(--c) h s calc(l * .9))`, `light-dark()`. Native colour math is here.                                                               |
| Mixins for theming                                     | The `.ex-btn` private-custom-property idiom (`--_bg` / `--_fg` overridden per variant) already replaces them, and reads better than an `@include`.                                                                                                 |
| `@media` bubbling                                      | Comes with native nesting.                                                                                                                                                                                                                         |
| `@each` / `@for` loops                                 | **Genuinely not in CSS.** Would save ~15 lines generating the `--xs/sm/lg/xl` scale modifiers. Small — a fixed 8-value scale is written once by hand.                                                                                              |
| Compile many partials → one file (`@use` / `@forward`) | The one real gap. See mitigations below.                                                                                                                                                                                                           |
| Minification (`style: :compressed`)                    | Propshaft does **none**; Sass would minify. After brotli at the edge (Thruster / Kamal) the net saving on a ~1,430-line file is ~5–10%. Marginal.                                                                                                  |
| Build-time errors, `@debug` / `@warn`                  | Minor.                                                                                                                                                                                                                                             |

### The trade

- **Cost of Sass:** a compile pass + a `dartsass:watch` process + an
  `assets:precompile` hook + `builds/` handling + the same
  `test:prepare`-not-run-by-`rake ci` CI gotcha documented for Tailwind in §9.
  (Dart Sass needs no Node — that part is fine.)
- **Benefit of Sass:** file bundling we do not need yet, loops that save ~15
  lines, and ~7% post-compression size.

Not worth it.

### Drawbacks of plain CSS, and how we mitigate them

- **No bundling of partials.** Addressed head-on — see *CSS file organisation*
  below. We split now (workflow reasons) and keep the cascade correct with
  `@layer` rather than file order.
- **No loops for repetitive rules.** Accept the handful of repeated lines in the
  scale modifiers; they are stable and read fine. A large *generated* utility
  layer is a Tailwind-shaped need and belongs in the §9 conversation, not a Sass
  one.
- **No minification.** Rely on the brotli/gzip compression already applied at the
  edge. Revisit only if CSS payload becomes a *measured* problem — and then reach
  for **Lightning CSS** (via `cssbundling-rails`), which is purpose-built for
  "author modern CSS, ship minified + autoprefixed + old-browser-downlevelled
  CSS", rather than Sass.
- **No compile-time checks.** Covered by the Stylelint step below, plus
  `slim_lint` and the component specs / Lookbook previews; a CSS syntax error
  also surfaces the moment the page renders in dev.

### When we would reconsider Sass

Only if we decide to generate a large utility layer programmatically (dozens of
spacing / colour / typography utilities) — which is the utility-first direction
§2 already rejected. Reactivating Sass for `$variables` or nesting alone buys
nothing over what the browser now does natively.

### CSS file organisation: split by concern, ordered with `@layer`

**Decision: split the single stylesheet into `app/assets/stylesheets/design/` —
one file for tokens, one for base, one for layout, one for typography, and one
per component / composed record — and control the cascade with native `@layer`,
not file order.** Do it in **Phase 1**, while everything is still small and
pre-rename.

The driver is workflow, not payload: small files are faster to navigate, a
DevTools "Workspace" edit lands as a 3-line diff in the right file, `git blame`
is per-component, and Lookbook's read-only CSS panel (§5) can just read the
component's own file instead of slicing a 1,400-line monolith.

**Layer order** — declared once, in `design/tokens.css`:

```css
@layer tokens, base, layout, typography, components, composed;
```

Every file wraps its rules (`@layer components { .ex-btn { … } }`). Cascade
order is then fixed by that list and **independent of the order the files load**
— which removes the one real hazard of splitting. (Custom properties resolve at
use time, so `--ex-*` never cared about order; it is base resets and
modifier-vs-base specificity ties that do, and `@layer` settles exactly those.)

**Loading** — an ordered array in `shared_partials/_design_head`, one `<link>`
per file, each with `data-turbo-track: "reload"`. **Not**
`stylesheet_link_tag :all` (alphabetical → `tokens` loads last), **not**
`@import` (render-blocking waterfall).

**`design/showcase.css`** — the showcase chrome (`.ex-section`, `.ex-swatch`,
`.ex-specimen`, `Example::*` helpers) moves here and is loaded **only** by the
`/example` layout and Lookbook, never app-wide. The split is what finally gets
this CSS off every app page.

**Guard** — a spec asserting every `design/*.css` is referenced by `_design_head`
(or have the partial glob the directory in an explicit order), so a new
`tooltip.css` cannot be silently forgotten.

Proposed files (~10–15):

```text
design/
  tokens.css       # fonts, colour, type scale, spacing, radii, shadows, motion (:root + dark)
  base.css         # .ex-scope / .ex-body, box-sizing, focus-visible, selection, reduced-motion, bare elements
  layout.css       # container, stack, cluster, grid, divider
  typography.css   # headings, lead, text, prose, blockquote, eyebrow
  button.css  link.css  badge.css  tag.css  card.css  field.css
  callout.css  avatar.css  figure.css  icon.css
  memory-card.css  chronicle-card.css
  showcase.css     # /example + Lookbook only
```

If request count or payload is ever *measured* as a problem, that is the trigger
for Lightning CSS / a concat step — unchanged from the minification note above.

### CSS linting & formatting: Prettier + Stylelint (not Biome)

**Decision: `prettier` (format) + `stylelint` (lint), wired into `rake ci`. No
Ruby gem exists for any of these — it is an npm dev-dependency toolchain, and
the project's first one.**

The value of linting a hand-authored design system is **convention
enforcement** — property ordering, the `--yui-*` / `--_*` custom-property naming
pattern, modern colour notation, no duplicate or descending-specificity
selectors. That is precisely where Biome's CSS support is thin: its CSS linter
is a small subset of `stylelint-config-recommended` (correctness only — no
ordering, no naming patterns). Biome's real win is one fast binary replacing
ESLint + Prettier on large **JS/TS** codebases; this is one growing CSS file
plus ~14 tiny Stimulus controllers, so that advantage does not apply. SCSS being
off the table removes Biome's main weakness but also its reason to exist here.
Prettier is additionally already running informally in the editor (it is what
reformats these tables) and also covers Markdown / JSON / YAML.

JS linting for the Stimulus controllers is a **separate, later decision** (Biome
or ESLint flat-config for `app/javascript/**`) — it must not drive the CSS
choice.

**Packages** (a `package.json` with `devDependencies` only — does not touch
importmap / Propshaft / runtime; importmap pins live in `config/importmap.rb`):

| Package                         | Role                                                                                                                                   |
|---------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `prettier`                      | formatter (CSS + Markdown + JSON + YAML)                                                                                               |
| `stylelint`                     | linter                                                                                                                                 |
| `stylelint-config-standard`     | baseline rules (Stylelint 16 dropped stylistic rules → no Prettier conflict; `stylelint-config-prettier` is deprecated and not needed) |
| `stylelint-config-recess-order` | property ordering                                                                                                                      |

Config: `.stylelintrc.json` extending both configs, with
`custom-property-pattern: "^(yui|ex|_)-[a-z0-9-]+$"`,
`at-rule-disallowed-list: ["import"]` (enforces the "no `@import`" rule from §4),
and (to start) `no-descending-specificity: null` and
`declaration-block-no-redundant-longhand-properties: null` — both noisy.
`.prettierignore` excludes `app/assets/stylesheets/pico.*.css` and
`app/assets/builds/`.

**Wiring** (mirror the `bin/mcp_*` convention):

- `bin/lint_css` → `stylelint "app/assets/stylesheets/**/*.css"` +
  `prettier --check` on the same glob.
- `bin/fix_css` → `stylelint --fix` + `prettier --write` (the `bin/mcp_rubocop -A`
  equivalent).
- `Rakefile`: add a `css` task and put it in the `ci` chain.
- CI (`.github/workflows/ci_push_pull_main.yml`): add
  `actions/setup-node@v4` (`node-version: "22"`, `cache: "npm"`) + `npm ci`
  before `bundle exec rake ci`. Commit `package-lock.json`; use `npm ci`.

Expect the first run to need one `bin/fix_css` pass plus a few rule disables —
`stylelint-config-standard` is opinionated.

If avoiding `node_modules` ever becomes a hard requirement, the only alternative
is Biome as a single vendored binary (`npx --yes @biomejs/biome` in CI, or the
release binary in `bin/`) — zero committed deps, but you lose property ordering
and the naming-pattern rule, which is most of the reason to lint a design
system. Not worth that trade here.

---

## 5. Add Lookbook for development

Adopt **[Lookbook](https://lookbook.build/)** as the component workbench
(Storybook-for-Rails). It is a **development dependency only** and does not ship
to production.

Why:

- Integrates natively with ViewComponent previews.
- Isolated per-state previews, live-editable params (`@param` magic comments),
  YARD notes, a11y panel (axe), viewport switcher.
- Removes the need to hand-maintain a showcase *for development* — every
  component gets a preview with all its variants, for free, next to the code.

Setup:

```ruby
# Gemfile
group :development do
  gem "lookbook"
end
```

```ruby
# config/routes.rb
mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?
```

- Put previews in `spec/view_components/previews/` (align with existing
  `spec/view_components/` layout) and point
  `config.view_component.preview_paths` / `config.lookbook.preview_paths` at it.
- Write one `*Preview` per component, starting with the ~20 primitives that
  already exist. Each preview method = one Specimen currently hand-written in
  `show.html.slim`.
- Wire Lookbook to load the `design/` stylesheets (+ fonts) in its preview
  layout — reuse `_design_head` so it can't drift from the app.

**CSS feedback loop.** Lookbook has no in-browser CSS editor. Two ways to get a
fast loop:

- **DevTools Workspace** — open a preview in its own tab (preview toolbar → open
  in new window), add `app/assets/stylesheets/design/` as a Sources → Workspace
  folder; edits in the Styles pane then save straight into the right
  `design/*.css` file (discard with `git checkout`). Editing `:root` tokens
  re-renders every specimen instantly — the highest-leverage move for token
  work.
- **Editor + auto-reload** — add the stylesheet dir to Lookbook's watch list so
  a save reloads the preview with no manual refresh:

  ```ruby
  config.lookbook.listen_paths << Rails.root.join("app/assets/stylesheets/design")
  config.lookbook.listen_extensions << "css"
  ```

  (needs the `listen` gem, already a Propshaft dev-perf recommendation.)

- **read-only "CSS" inspector panel**  
  (`config.lookbook.preview_inspector.drawer_panels`) — now trivial with split
  files: map `button_component.rb` → `design/button.css` and show that file.
  Low priority once the two loops above exist.

**`/example` stays** (see §6) — Lookbook is the daily driver, `/example` is the
curated narrative.

---

## 6. Keep `/example`

Keep the `/example` route, `layouts/example`, `ExampleController`, and
`app/views/example/show.html.slim` as a **living, curated design-language page**:

- Onboarding reference for contributors ("this is our voice").
- A single URL to eyeball the whole system after a token change.
- A place the narrative (why Fraunces, why terracotta, the record model) is told —
  Lookbook is deliberately atomic and doesn't do narrative.

Maintenance expectations:

- When a primitive's API changes, update its Specimen on `/example` **and** its
  Lookbook preview. Two touch-points is acceptable for ~20 primitives.
- The showcase-only components (`SectionComponent`, `SpecimenComponent`,
  `SwatchComponent`, `Example::*` chrome) stay in the `Example::` namespace even
  if the primitives get renamed (see Phase 1).
- Keep it out of the sitemap / add `noindex` (already present).

---

## 7. Rollout plan — from `/example` to the whole app

Ship in phases; each phase leaves the app fully working. Rough size in focused
days is indicative.

### Component & template conventions

Applies to every new `Yui::` primitive, and to each app component as it is
touched during the phases below.

#### Template placement

| Template                                              | Where it lives                                                                                     |
|-------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| > ~5 lines, or any `- if` / `- each` / multiple slots | Sidecar file, the DEFAULT — `app/view_components/yui/button_component.html.slim` next to the `.rb` |
| ≤ ~5 lines, no logic                                  | Inline `slim_template <<~SLIM` but only for existing files                                         |
| Trivial wrapper (1–2 lines, one element)              | No template — override `call` / use `content_tag`                                                  |

Why sidecar by default: `slim_lint` runs in CI but only scans `.slim` files, so
inline heredocs are currently **unlinted** (44 components); sidecar files also
get editor highlighting, the Slim LSP, format-on-save, and keep markup churn out
of the `.rb` file and its `git blame`. Slim is whitespace-significant, so a
heredoc indented inside a class body is error-prone — keep only the shortest
templates inline.

#### Heredoc style

Where a template stays inline, use `<<~SLIM` (squiggly).
Never `<<-SLIM` (does not strip indentation → fragile) or bare `<<SLIM`. Use the
quoted terminator `<<~'SLIM'` only when the template contains `#{...}` that must
reach the browser literally.

#### CSS file placement

CSS is **not** co-located with the component `.rb` (Propshaft does not serve
ViewComponent sidecar CSS). Each component's rules live in its own file under
`app/assets/stylesheets/design/` (`design/button.css` for `Yui::ButtonComponent`),
wrapped in `@layer components { … }` (or `@layer composed { … }` for the record
cards). Tokens, base and layout stay in `design/tokens.css` / `base.css` /
`layout.css`. New file → add it to the `_design_head` ordered list (the guard
spec fails otherwise). See §4 for the layer order and rationale.

### Phase 0 — Foundations & tooling (~1–1.5 days)

- [x] Remove dead `dartsass-rails` setup (§3).
- [x] Add **Prettier + Stylelint** (§4): `package.json` (devDeps only),
      `.stylelintrc.json`, `.prettierignore`, `bin/lint_css` + `bin/fix_css`, a
      `css` task in the `rake ci` chain, and the `actions/setup-node` + `npm ci`
      step in CI. Run `bin/fix_css` once and commit the reformat + any rule
      disables as a standalone commit. (scoped to `example.css`; the legacy
      Pico-era stylesheets are `ignoreFiles`'d — they go in Phase 6.)
- [x] Add Lookbook (§5); previews for the existing ~20 primitives in
      `spec/view_components/previews/`. (21 `*Preview` classes; `component_preview`
      layout renders them in the design-language `<head>`; mounted at `/lookbook`
      in development. VC previews path set in `config/application.rb`, not an
      initializer — the railtie reads it too early otherwise.)
- [x] Add component specs (`spec/view_components/`) for the primitives — render +
      key variants + a11y assertions. `capybara` + `rspec` already available.
      (80 examples across 16 files; surfaced + fixed the `aria-invalid` boolean-
      attribute bug in `FieldComponent` and the missing scoping class on the
      composed cards.)
- [x] Self-host Fraunces + Inter as `woff2` in `app/assets/fonts/` with
      `@font-face` in `example.css` (Propshaft fingerprints them); drop Google Fonts `<link>`.
- [x] Shared `shared_partials/_design_head` partial: `@font-face` + `stylesheet_link_tag`.
      (`@font-face` lives in `example.css`; the partial preloads the roman fonts + links the sheet.)
- [x] Decide the `.ex-scope` strategy: scope on `<main>` in each layout.
      → **D1** in `TODOs_IDEAs_CONTEXT/DECISIONS_UI_DESIGN.md`.
- [x] Heredoc hygiene: fix the `<<-SLIM` in
      `admin_index_record_events_component.rb` to `<<~SLIM` (also looks like it is
      missing a `-` before `.each` — verify it renders), and standardise every
      surviving inline template on `<<~SLIM` (`<<~'SLIM'` only where interpolation
      must stay literal). Confirm output unchanged via component specs / Lookbook.
      Do this before the sweeps so later diffs stay clean. (was the only `<<-`;
      the missing `-` was confirmed and fixed with a regression spec. Also
      noted: `AdminShowRecordEventComponent` has similar inline-text bugs —
      `strong Event:` swallows the nested `= …`, and it uses `slim/smart` `>`
      indicators — to be fixed when it is rewritten in Phase 5.)

### Phase 1 — Namespace, conventions, CSS split & data-access decision (~1.5 days)

- [x] **Namespace**: `Example::` reads as throwaway. Rename the *primitives* to
      **`Yui::`** ("Yournaling UI" — a deliberately app-specific prefix so the
      namespace stays unique even if a third-party component library is added
      later). Keep `Example::` only for showcase chrome. This is cheapest now
      (≈0 production call sites). Update `/example` + previews. (CSS classes /
      tokens stay `.ex-*` / `--ex-*` — the token rename, if any, is later.)
- [x] **Data access**: primitives inherit `ViewComponent::Base`, so they cannot
      see `current_user` / policies / helpers. **Keep them pure**: callers pass
      plain values (`href:`, `title:`, `author_name:`, …). Authorization and
      record → view-model mapping happen in **app-level wrapper components**
      (`ApplicationComponent` subclasses) or the controller/view, never inside a
      `Yui::` primitive. Document this rule in `Yui::BaseComponent`.
- [x] Implement **form strategy**: a thin `YuiFormBuilder <
      ActionView::Helpers::FormBuilder` whose `text_field` / `select` / `collection`
      helpers emit `.ex-field` markup (wrapping `Yui::FieldComponent`). Used
      opt-in per form (e.g. `form_with ..., builder: YuiFormBuilder`) during migration
      so existing forms migrate incrementally without breaking. Prototype against one form.
      (input family + textarea + select + collection_select + check_box + submit;
      spec in `spec/form_builders/`; prototyped as a specimen in the /example Forms section.)
- [x] Adopt the **Component & template conventions** above: author every `Yui::`
      primitive with a sidecar `.slim` (or no template for trivial wrappers);
      move the ~20 renamed `Example::*` templates to sidecar as part of the
      rename. Add the rule to `Yui::BaseComponent`'s doc comment. (13 → sidecar,
      4 trivial → `def call`; no inline `slim_template` left in `Yui::`.)
- [x] **Split the stylesheet** (§4): create `app/assets/stylesheets/design/`,
      declare `@layer tokens, base, layout, typography, components, composed;` in
      `design/tokens.css`, move `example.css` into per-concern / per-component
      files each wrapped in its layer, move the showcase chrome to
      `design/showcase.css` (loaded only by `/example` + Lookbook). Update
      `_design_head`, the `/example` layout and the Lookbook preview layout to
      the ordered `<link>` list; add the "every `design/*.css` is referenced"
      guard spec. Land the mechanical move as its own commit. Point Stylelint
      (`.stylelintrc.json` glob) and `.prettierignore` at the new dir. (17 files;
      `_design_head` takes `showcase:`; guard in `spec/views/design_head_spec.rb`.)

### Phase 2 — Shared chrome (~2–2.5 days)

Convert the components every layout renders, then start pulling Pico.

**Dev feedback loop for CSS (do first — §5).** The split files (Phase 1) make
all three cheap; ship them before the chrome sweep so editing `design/*.css` is
fast throughout.

- [x] **DevTools Workspace** — write up the one-time setup in
      `app/assets/stylesheets/design/README.md` (open a preview in its own tab
      → Sources → add `design/` as a Workspace folder → Styles-pane edits save
      into the right file; `git checkout` to discard). Zero code; highest
      leverage for token work.
- [x] **Editor + auto-reload** — `listen` in the `:development` group,
      `config.file_watcher = ActiveSupport::EventedFileUpdateChecker` in
      `development.rb`, and in `config/application.rb`:
      `config.lookbook.live_updates = true` +
      `listen_paths << …/design` + `listen_extensions << "css"`.
      (`live_updates` is the extra bit the §5 snippet missed — without it the
      watcher reloads previews server-side but the browser doesn't refresh.
      `Lookbook::Engine.auto_refresh?` is now `true`.)
- [x] **Read-only "CSS" inspector panel** — `Lookbook.add_panel("css", …)` in a
      dev-guarded initializer; `DesignCssPanel.name_for` maps
      `Yui::ButtonComponentPreview` → `design/button.css` (dasherised), with a
      SHARED fallback for primitives whose rules live in a layer file
      (typography / layout / field). Rendered read-only + highlighted via
      `lookbook_render :code`; the `"*"` in `drawer_panels` slots it next to
      Source/Notes/Params — no `preview_inspector` config needed.

**Shared chrome.**

- [ ] Layouts: add `_design_head`, wrap `main` in `.ex-scope`, add
      `data-area` for the colour override.
- [ ] Nav: `ApplicationNavComponent`, `AdminNavComponent`,
      `CurrentTeamNavComponent`, `ApplicationNavLinksComponent`,
      `ApplicationNavActionsComponent`, `NavNewButtonComponent`,
      `TeamSwitcherAndSessionsComponent` → build a `Yui::Navbar` +
      `Yui::NavItem` and rewrite the component templates against them.
- [ ] Chrome: `shared_partials/_flash_notifications` → `Yui::Toast` /
      `Yui::Callout`; scroll-to-top button; `BrowseHeaderComponent` /
      `ManageHeaderComponent` / `manage`/`browse` headers.
- [ ] Interactive: create dedicated Stimulus controllers under a `yui`
      namespace / prefix (e.g. `yui-dropdown`, `yui-modal`, `yui-tabs`) wired to
      `.ex-dropdown` / `Yui::Modal` / `Yui::Tabs` markup. This allows old Pico
      controllers and new Yui controllers to coexist cleanly during migration.
      Retire `details.dropdown` and `dialog > article` Pico idioms on migrated
      components.
- [ ] Once nav + flash are converted, the chrome no longer needs Pico — but
      leave the `pico.*` links until each area's `<main>` is done.
- [ ] As each of these components is rewritten, move its template to a sidecar
      `.slim` per the conventions above (the nav components are the heaviest
      inline heredocs in the repo).

New primitives needed here (not yet in `/example`): `Navbar`, `NavItem`,
`Modal`, `Tabs`, `Menu`/`Dropdown` (interactive), `Toast`, `Pagination`
(pagy), `Table`, `Breadcrumb`, `EmptyState` (an app one exists —
`EmptyStateComponent` — restyle it).

### Phase 3 — Public / `application` layout (~1–2 days)

Templates under the default layout: `pages/*` (feed, show, error),
`searches/*`, `users/*`, `logins/*`, `registrations/*`, `passwords/*`,
`email_verifications/*`, `teams/*` (public views), `switch_current_teams/*`.

- [ ] Sweep each template: replace bare elements with `Yui::*`, delete inline
      `style="…"`, replace `role="button" class="secondary"` →
      `Yui::ButtonComponent`.
- [ ] Convert `SearchFormComponent`, `SearchResultsComponent`,
      `ExternalLinkComponent`, `MapLinkComponent`, `DeviceComponent` — sidecar
      their templates while touched.
- [ ] Drop `pico.amber` link from `layouts/application`.
- [ ] QA against screenshots taken in Phase 0.

### Phase 4 — Team workspace / `current_team_area` (~2–3 days)

The largest area: `current_teams/{chronicles,memories,thoughts,weblinks,
locations,pictures,members,pages}` — index / show / new / edit / `_form` /
`_record` partials, plus `InsightAttachmentManagerComponent`,
`ChronicleAttachedEntriesFormComponent`, `ChronicleEntryComponent`,
`ContentVisibilityModalComponent`, `InsightDestroyModalComponent`,
`InsightsDropdownComponent`, `PictureLightboxComponent`,
`PictureSelectFieldComponent`, `DeviceLocationComponent`.

- [ ] Lean on the form strategy from Phase 1 — this area is form-heavy and has
      the `role="group"` / inline-`grid` partials.
- [ ] Port `card.css` (`.timeline-grid`, `.yournal-card`, chips, timeline track)
      into `design/card.css` / `design/memory-card.css` / `design/chronicle-card.css`,
      de-`--pico-*`'d — the `Yui::MemoryCard` / `Yui::ChronicleCard` already
      cover most of it.
- [ ] Restyle the lightbox (`PictureLightboxComponent` + its Stimulus).
- [ ] Sidecar the template of every component rewritten in this area.
- [ ] Drop `pico.green` link.

### Phase 5 — Admin / `admin_area` (~1 day)

`admins/{chronicles,memories,thoughts,weblinks,locations,pictures,members,
teams,users,pages,record_events}` — mostly index + edit + destroy, plus
`AdminNavComponent`, `AdminActionsComponent`, `AdminShow*Component`,
`AdminIndexRecordEventsComponent`.

- [ ] These are utilitarian — `Yui::Table`, `Yui::Button`, `Yui::Field`, `Yui::Badge`
      cover ~all of it.
- [ ] Sidecar the `AdminShow*` / `AdminActions` / `AdminIndexRecordEvents`
      component templates as they are rewritten — this clears the last inline
      heredocs.
- [ ] Drop `pico.blue` link.

### Phase 6 — Teardown & hardening (~0.5–1 day)

- [ ] Delete `pico.amber/blue/green.css` (local copies) and all CDN
      `stylesheet_link_tag "https://unpkg.com/..."` lines.
- [ ] Delete `picocss_reset.css`, `rails_reset.css`, `admin.css`; fold anything
      still needed into the relevant `design/*.css` layer.
- [ ] Remove every remaining `var(--pico-*)` reference — enforce with a Stylelint
      rule (`declaration-property-value-disallowed-list` or a `no-restricted-syntax`
      pattern) rather than a bare grep.
- [ ] Verify no external Google Fonts or CDN font references remain (self-hosting completed in Phase 0).
- [ ] Re-enable and tighten CSP now that there is no external CSS/JS/font host.
- [ ] Confirm no `example.css` / `Example::` stylesheet references linger (the
      `design/` split in Phase 1 already retired the filename).
- [ ] Add a `slim_lint` / grep check that new templates don't reintroduce bare
      unstyled elements or inline `style=`.
- [ ] Add a grep gate: no `<<-SLIM` / bare `<<SLIM` heredocs, and no inline
      `slim_template` over ~5 lines — enforces the Component & template
      conventions for future components.
- [ ] Final screenshot-diff pass on key screens.

### Effort summary

| Phase                                                  | Size                                                       |
|--------------------------------------------------------|------------------------------------------------------------|
| 0 — foundations & tooling                              | ~1–1.5 days                                                |
| 1 — namespace / conventions / CSS split / data / forms | ~1.5 days                                                  |
| 2 — shared chrome + Stimulus                           | ~2 days                                                    |
| 3 — public layout                                      | ~1–2 days                                                  |
| 4 — team workspace                                     | ~2–3 days                                                  |
| 5 — admin                                              | ~1 day                                                     |
| 6 — teardown + CSP                                     | ~0.5–1 day                                                 |
| **Total**                                              | **~10–13 focused days**, shippable at every phase boundary |

---

## 8. Cost of changing a base ViewComponent later

This is the core trade-off of the chosen approach, so it is worth being precise.

### Cheap changes (the reason we chose this)

- **Token change** (`--ex-accent`, `--ex-radius-*`, `--ex-space-*`, a font):
  one edit in `example.css`, propagates everywhere instantly, themeable,
  verifiable on `/example` + Lookbook in seconds. **Cost: minutes.**
- **Visual change to a primitive's CSS** (button padding, card shadow, input
  border): one rule in `example.css`. No template touched. Every call site
  updates. **Cost: minutes to an hour.**
- **New variant** (`variant: :subtle` on `Yui::Badge`): add a modifier class +
  extend the component's `VARIANTS` array + one preview. Additive, no call site
  breaks. **Cost: under an hour.**

### Expensive changes (design the API to avoid these)

- **Renaming or removing a prop** (`variant:` → `tone:`): every call site must
  change. With N call sites that is N edits + review.
- **Changing the rendered DOM / slot structure** (e.g. `CardComponent` gains a
  required wrapper element): breaks anything that targeted the old structure in
  CSS or Stimulus, plus any override.
- **Changing default behaviour** (button default `variant` flips from `:primary`
  to `:secondary`): silent visual regressions across the app.

### How the cost scales

- **Right now the cost is near zero** — the only call sites are `/example` and
  previews. Every week the app grows on Pico markup, the eventual migration cost
  rises and the "change a primitive" cost rises with the number of call sites.
  **This is the strongest argument for prioritising the rollout in §7.**
- After rollout, expect each primitive to have tens to low-hundreds of call
  sites. At that scale:
  - visual/token iteration stays ~free (the payoff),
  - a structural change to `Yui::Button` or `Yui::Card` is a half-day chore with a
    codemod-style find-and-replace + full visual QA,
  - a structural change to `Yui::Field` (used in every form) is the most
    expensive single thing and should go through a deprecation cycle.

### Mitigations (adopt from Phase 1)

- **Keep primitive APIs small and stable.** Resist over-parameterising. If a
  screen needs something bespoke, compose primitives in an app-level component
  rather than adding a niche prop.
- `ex_token(value, allowed:, default:)` is already used — bad inputs degrade to
  the default instead of raising. Keep that pattern.
- **Component specs + Lookbook previews** are the regression net for structural
  changes. Every primitive must have both before it gets real call sites.
- **Wrap, don't fork.** App-specific needs live in `ApplicationComponent`
  subclasses that render `Yui::*` internally, so a future swap of the primitive
  is one file.
- Treat `Yui::Field` / `Yui::Button` / `Yui::Card` as **stable API** — changes go
  through a deprecation path (support old + new prop for one release).

---

## 9. Alternative: switching to Tailwind CSS

Recorded for completeness. This section **ignores the `/example` work** and
evaluates Tailwind on its own merits, as if starting the CSS decision fresh.

### Pros

- **Rails 8 default** — `rails new --css tailwind` generates exactly this; matches
  "stay close to Rails 8 recommendations".
- Large community, extensive docs, editor autocomplete, class-sorting tooling,
  broad contributor familiarity.
- **No Node required** — `tailwindcss-rails` (v4) depends on `tailwindcss-ruby`,
  which vendors a standalone CLI binary.
- Utility velocity for one-off layout without opening a CSS file.
- Tree-shaking → small final stylesheet.
- `@tailwindcss/typography` gives a strong `prose` out of the box (covers
  `ProseComponent`'s job).
- v4 is CSS-first (`@theme`, `@import "tailwindcss"`) — no `tailwind.config.js`.

### Cons

- **Discards ~1,430 lines of tuned, reviewed CSS + ~20 components + the
  showcase.** Large sunk cost for no functional gain.
- **Adds a build step**: `tailwindcss:watch` in dev, `tailwindcss:build`
  auto-attached to `assets:precompile`. Plus a **CI gotcha** — the gem attaches
  the build to `test:prepare`, but this repo runs tests via a custom `rake ci` /
  `parallel_rspec` that does **not** invoke `test:prepare`; any request/system
  spec rendering `stylesheet_link_tag "tailwind"` then raises
  `Propshaft::MissingAssetError`. Fix: prepend `tailwindcss:build` to the `ci`
  task and add it to `bin/setup` + the Actions job.
- **Preflight resets everything** — you still have to restyle every one of the
  ~167 classless templates. The template-sweep lift is identical to the
  chosen path; only the "what do I type" differs (utilities vs `Yui::*`).
- **Utility soup in Slim** unless you *also* wrap everything in ViewComponents —
  in which case you have built a component system anyway, just with Tailwind as
  the implementation detail.
- Holding a distinctive editorial identity in utility classes takes discipline;
  the default outcome looks generic.
- Two ways to express the same thing (utilities vs `@apply` component classes)
  invites inconsistency.

### If we switched anyway — steps

1. `bundle remove dartsass-rails`; `bundle add tailwindcss-rails --version "~> 4.0"`;
   `bin/rails tailwindcss:install`.
2. Port `--ex-*` tokens into `@theme`; port `.ex-*` component CSS into
   `@layer components` with `@apply`, **keeping the `Yui::*` ViewComponent APIs
   unchanged** so call sites don't care about the implementation.
3. `Procfile.dev`: swap `dartsass:watch` → `tailwindcss:watch` (or add
   `plugin :tailwindcss` to `config/puma.rb`).
4. Wire `tailwindcss:build` into `rake ci`, `bin/setup`, and
   `.github/workflows/ci_push_pull_main.yml`. Keep `app/assets/builds/` gitignored.
5. Migrate layouts to a single `stylesheet_link_tag "tailwind"`; then roll out
   per area using the **same Phase 3–5 sequence** as §7.
6. Add `@source "../../view_components";` to the input file so classes inside
   `slim_template` heredocs in `.rb` components are detected.
7. `@plugin "@tailwindcss/typography"` for prose.
8. Delete Pico, re-enable CSP (no external host needed).
9. Optional: `prettier-plugin-tailwindcss` (needs Node in dev only) for class
   sorting, or accept unsorted classes.

### Verdict

Tailwind would have been a reasonable original choice. **Given `/example`
already exists and is good, switching now is negative expected value**: same
template-sweep work, plus tooling/porting overhead, minus the identity we've
already built. The only defensible hybrid is step 2 in isolation — keep the
tokens and `Yui::*` components, implement their CSS via Tailwind `@apply` — and
that buys ecosystem familiarity for the price of a build step and the CI fix,
which we don't currently need.

**Decision: proceed with §2–§8. Revisit Tailwind only if the team composition or
tooling priorities change materially.**
