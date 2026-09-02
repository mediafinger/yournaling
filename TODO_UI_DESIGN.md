# TODO UI Design

Status: **planning** · Owner: andy · Created 2026-08-31

This document is the plan for moving Yournaling's UI from Pico.css to the
bespoke **"Warm Editorial"** design language that already lives under
`/example`. It also records, at the end, the alternative we are _not_ taking
(switching to Tailwind CSS) with its trade-offs, so the decision is traceable.

---

## 1. Starting point (snapshot, 2026-08-31)

This section is a **frozen snapshot** of the codebase when the plan was written —
it is not updated as work lands. Progress is tracked by the checkboxes in §7.
As of 2026-09-02: Phases 0–5 done. All three layouts are Yui-only — no
`pico/*` link anywhere. `example.css` is `app/assets/stylesheets/design/*.css`;
the primitives are `Yui::` with sidecar templates (no inline `slim_template`
heredocs left); fonts self-hosted; Lookbook installed with a render-smoke
spec. Remaining: Phase 6 (delete the dead Pico files, Stylelint `--pico-*`
ban, re-enable CSP, the `.ex-*` → `.yui-*` rename, grep gates).

### Styling stack

| Piece          | Detail                                                                                                                                                                                                                                 |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
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
  - **Scoped, not global**: everything hangs off `.ex-body` _or_ `.ex-scope`.
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
  The `design/*.css` files are served directly by Propshaft — **no build step,
  no runtime Node, no watcher, no CI asset compilation.** (A dev-only Node
  toolchain lints/formats the CSS — see §4.)
- A token-driven ViewComponent system gives us the thing utility classes cannot:
  a visual change is one edit in one place, not a find-and-replace across
  hundreds of templates (see §8).

Third-party libraries were considered and rejected:

| Option                              | Why not                                                                                                                                                                                                                                  |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **DaisyUI**                         | CSS-only (Turbo-friendly, no JS to re-init) and easy to _theme_, but its rounded "SaaS" aesthetic is the opposite of Warm Editorial; re-skinning it to match = the work we've already done. Best when you have _no_ system. We have one. |
| **Flowbite / Preline / Franken UI** | Ship their own vanilla JS that must be re-initialised on every Turbo navigation / frame render — a recurring papercut. Heavier. "Copy the markup" rather than semantic classes.                                                          |
| **Tailwind Plus (ex-Tailwind UI)**  | High quality, no runtime, but paid and React-flavoured; still needs porting to Slim/ViewComponent. Keep as a _reference_ for focus states / ARIA wiring only.                                                                            |
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

The `design/*.css` files are **scoped** (`.ex-scope` / `.ex-body`) and their
`base` layer defines **no global reset or bare-element rules**. Pico's
`--pico-*` variables and the `--ex-*` tokens do not collide. So we can:

1. Wrap a layout's `<main>` (or any subtree) in `.ex-scope` and it renders in the
   new design while the surrounding chrome stays on Pico.
2. Migrate view by view inside that scope.
3. Once every template a layout renders is converted **and** that layout's nav /
   header / flash components are converted, drop the `pico.<colour>` link from
   that layout.
4. When the last layout is done, delete Pico and the custom `--pico-*` CSS.

### Interim rules

- **Never load Pico and the `design/` sheets as competing full-page systems.**
  Scope the design language to main content (`.ex-scope` on `<main>`); leave
  Pico owning the chrome until the nav components are ported (Phase 2).
- The three per-area accent colours (amber / green / blue) carry over as an
  `--ex-accent` override per layout — add a `data-area` attribute or body class
  and redefine `--ex-accent*` for `[data-area="team"]` / `[data-area="admin"]`
  in `design/tokens.css`. Default stays the terracotta.
- Keep `data-turbo-track: "reload"` on the stylesheet tag.

### Asset-handling changes for this path (minimal)

- ✅ **Remove `dartsass-rails`**, the dead `application.scss`, the empty
  `app/assets/builds/application.css`, and the `css:` line in `Procfile.dev` —
  done in Phase 0 (`fa60a8c`). Propshaft serves the `design/*.css` files
  directly.
- ✅ **Self-host Fraunces + Inter** as `woff2` in `app/assets/fonts/` with
  `@font-face` in `design/tokens.css` (Propshaft fingerprints them) — done in
  Phase 0; the Google CDN dependency is gone and CSP is simpler.
- ✅ **Retire the `example.css` filename** by splitting it into
  `app/assets/stylesheets/design/` (see §4 → _CSS file organisation_) — done in
  Phase 1 alongside the `Yui::` rename.
- **CSP**: when re-enabled (Phase 6), no external style/script host is needed if
  fonts are self-hosted. The `csp_meta_tag` is already in the layouts.
- ✅ **CI / tests**: no runtime build artefact. `rake ci` gained one step — the
  Prettier + Stylelint `css` task (§4), with `actions/setup-node` + `npm ci`
  added to the CI tests job and `npm install` to `bin/setup`; still no asset
  compilation. (Contrast with §9.)

---

## 4. Preprocessor, linting & formatting

Three decisions: **no Sass/SCSS** (author plain CSS); **split the stylesheet by
concern, ordered with `@layer`**; and **add Prettier + Stylelint to `rake ci`**.

### Preprocessor: why we stay on plain CSS (no Sass/SCSS)

**Decision: no Sass/SCSS. The `design/*.css` files stay plain CSS, authored with
native CSS nesting and `@layer` where it aids readability.**

The inert `dartsass-rails` setup (see §1) tempts a "reactivate it properly"
move. We won't. Modern CSS has absorbed almost everything Sass existed to
provide, and adopting Sass would re-introduce exactly the build step that §2 and
§3 are built around _not_ having.

### What Sass would give us — and the native-CSS equivalent

| Sass feature                                           | Our situation                                                                                                                                                                                                                                      |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$variables`                                           | We use CSS custom properties (`--ex-*`). Strictly **better** here: runtime, cascade-aware, devtools-inspectable — and the reason the `prefers-color-scheme` dark-mode token swap works at all. Sass variables are compile-time and cannot do that. |
| Nesting, `&`                                           | **Native CSS nesting** ships in every browser we support (Baseline 2023). Adopt freely, zero tooling.                                                                                                                                              |
| `darken()` / `lighten()` / `mix()`                     | **`color-mix()`** (already used in `design/callout.css` for the borders), relative colour syntax `hsl(from var(--c) h s calc(l * .9))`, `light-dark()`. Native colour math is here.                                                                |
| Mixins for theming                                     | The `.ex-btn` private-custom-property idiom (`--_bg` / `--_fg` overridden per variant) already replaces them, and reads better than an `@include`.                                                                                                 |
| `@media` bubbling                                      | Comes with native nesting.                                                                                                                                                                                                                         |
| `@each` / `@for` loops                                 | **Genuinely not in CSS.** Would save ~15 lines generating the `--xs/sm/lg/xl` scale modifiers. Small — a fixed 8-value scale is written once by hand.                                                                                              |
| Compile many partials → one file (`@use` / `@forward`) | The one real gap. See mitigations below.                                                                                                                                                                                                           |
| Minification (`style: :compressed`)                    | Propshaft does **none**; Sass would minify. After brotli at the edge (Thruster / Kamal) the net saving on the ~1,650 lines of `design/*.css` is ~5–10%. Marginal.                                                                                  |
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

- **No bundling of partials.** Addressed head-on — see _CSS file organisation_
  below. We split now (workflow reasons) and keep the cascade correct with
  `@layer` rather than file order.
- **No loops for repetitive rules.** Accept the handful of repeated lines in the
  scale modifiers; they are stable and read fine. A large _generated_ utility
  layer is a Tailwind-shaped need and belongs in the §9 conversation, not a Sass
  one.
- **No minification.** Rely on the brotli/gzip compression already applied at the
  edge. Revisit only if CSS payload becomes a _measured_ problem — and then reach
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
one file for tokens, one for base, one for layout, one for typography, one per
component / composed record, plus `showcase.css` — and control the cascade with
native `@layer`, not file order.**

**Done in Phase 1** (`9fa4acd`): 17 `design/*.css` files +
`spec/views/design_head_spec.rb` as the guard; the `design/README.md` map
followed in Phase 2 (`e7acf19`).

The driver is workflow, not payload: small files are faster to navigate, a
DevTools "Workspace" edit lands as a 3-line diff in the right file, `git blame`
is per-component, and Lookbook's read-only CSS panel (§5) reads the component's
own file (`Yui::ButtonComponent` → `design/button.css`) instead of slicing a
monolith.

**Layer order** — declared once, at the top of `design/tokens.css`:

```css
@layer tokens, base, layout, typography, components, composed, showcase;
```

Every file wraps its rules (`@layer components { .ex-btn { … } }`). Cascade
order is then fixed by that list and **independent of the order the files load**
— which removes the one real hazard of splitting. (Custom properties resolve at
use time, so `--ex-*` never cared about order; it is base resets and
modifier-vs-base specificity ties that do, and `@layer` settles exactly those.)
`@font-face` stays unlayered at the top of `tokens.css`.

**Loading** — an ordered `%w[…]` array in `shared_partials/_design_head`, one
`<link>` per file, each with `data-turbo-track: "reload"`. **Not**
`stylesheet_link_tag :all` (alphabetical → `tokens` loads last), **not**
`@import` (render-blocking waterfall — and now blocked by a Stylelint rule, §4).

**`design/showcase.css`** — the showcase chrome (`.ex-showcase*`, `.ex-section`,
`.ex-swatch`, `.ex-specimen`) lives in its **own `showcase` layer, above
everything**, and is loaded **only** by the `/example` layout and the Lookbook
preview layout (`_design_head`'s `showcase: true`), never app-wide.

**Guard** — `spec/views/design_head_spec.rb` asserts every `design/*.css` is
listed in `_design_head` exactly once, `tokens` first, and `showcase` not in the
app-wide set — so a new `tooltip.css` cannot be silently forgotten.

Actual files:

```text
design/
  README.md
  tokens.css       # @layer tokens — @font-face + fonts, colour, type scale, spacing, radii, shadows, motion (:root + dark)
  base.css         # @layer base — .ex-scope / .ex-body, box-sizing, focus-visible, selection, reduced-motion
  layout.css       # @layer layout — container, stack, cluster, grid, divider
  typography.css   # @layer typography — headings, lead, text, prose, blockquote, eyebrow
  button.css  link.css  badge.css  tag.css  card.css  field.css   # @layer components
  callout.css  avatar.css  figure.css  icon.css                   # @layer components
  memory-card.css  chronicle-card.css                             # @layer composed
  showcase.css     # @layer showcase — /example + Lookbook only
```

If request count or payload is ever _measured_ as a problem, that is the trigger
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
ESLint + Prettier on large **JS/TS** codebases; this is ~17 small `design/*.css`
files plus ~14 tiny Stimulus controllers, so that advantage does not apply. SCSS
being off the table removes Biome's main weakness but also its reason to exist
here.
Prettier is additionally already running informally in the editor (it is what
reformats these tables) and also covers Markdown / JSON / YAML.

JS linting for the Stimulus controllers is a **separate, later decision** (Biome
or ESLint flat-config for `app/javascript/**`) — it must not drive the CSS
choice.

**Packages** (a `package.json` with `devDependencies` only — does not touch
importmap / Propshaft / runtime; importmap pins live in `config/importmap.rb`):

| Package                         | Role                                                                                                                                   |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `prettier`                      | formatter (CSS + Markdown + JSON + YAML)                                                                                               |
| `stylelint`                     | linter                                                                                                                                 |
| `stylelint-config-standard`     | baseline rules (Stylelint 16 dropped stylistic rules → no Prettier conflict; `stylelint-config-prettier` is deprecated and not needed) |
| `stylelint-config-recess-order` | property ordering                                                                                                                      |

As shipped (`.stylelintrc.json`, extends `stylelint-config-standard` +
`stylelint-config-recess-order`):

- `custom-property-pattern: "^(ex|yui)-…$|^_…$"` — `--ex-*` / `--yui-*` / `--_*`.
- `at-rule-disallowed-list: ["import"]` — enforces the "no `@import`" rule (§4).
- `selector-class-pattern` — BEM kebab-case (`block__element--modifier`), added
  during the first pass.
- `value-keyword-case` — lower, ignoring `font` shorthands + `optimizeLegibility`
  and friends.
- `no-descending-specificity` and
  `declaration-block-no-redundant-longhand-properties` disabled — both noisy.
- `ignoreFiles`: `node_modules/**`, `app/assets/builds/**`.

**Scope**: only the hand-authored design system is linted/formatted —
`bin/css_lint` (add `-a` to auto-correct) globs `app/assets/stylesheets/design/**/*.css`, and
`.prettierignore` excludes `app/assets/stylesheets/*.css` (the legacy Pico-era
sheets, gone in Phase 6) plus `builds/`, `Gemfile.lock`, `package-lock.json`.
(The plan originally said `stylesheets/**` — narrowing to `design/` is the right
call and what shipped.)

**Wiring** (mirrors the `bin/mcp_*` convention) — all done in Phase 0
(`18dd913`, `fdcb2b8`):

- `bin/css_lint` → `stylelint` + `prettier --check` on the `design/` glob.
- `bin/css_lint -a` (or `autocorrect`) → `stylelint --fix` + `prettier --write`
  (the `bin/mcp_rubocop -A` equivalent).
- `Rakefile`: a `css` task in the `ci` chain (`zeitwerk:check rubocop slim_lint
css factory_bot:awesome_lint db:doctor rspec …`).
- CI: `actions/setup-node@v4` (`node-version: "22"`, `cache: "npm"`) + `npm ci`
  in the tests job; `package-lock.json` committed. `bin/setup` runs
  `npm install`.

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
- Removes the need to hand-maintain a showcase _for development_ — every
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

- Previews live in `spec/view_components/previews/yui/` — path set in
  `config/application.rb` (`config.view_component.previews.paths <<`, **not** an
  initializer: the VC railtie reads it too early otherwise), with
  `config.lookbook.preview_paths = config.view_component.previews.paths`.
- One `*Preview` per component (21 shipped). Each preview method mirrors a
  Specimen on `/example`.
- The preview layout is `component_preview` — it renders `_design_head` with
  `showcase: true`, so previews can't drift from the app's `<head>`.

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
  # config/application.rb
  config.lookbook.live_updates = true   # ← required; without it the watcher
                                        #   reloads server-side but the browser
                                        #   never refreshes
  config.lookbook.listen_paths << Rails.root.join("app/assets/stylesheets/design").to_s
  config.lookbook.listen_extensions << "css"
  ```

  Needs the `listen` gem (now in the `:development` group) **and**
  `config.file_watcher = ActiveSupport::EventedFileUpdateChecker` in
  `development.rb` — also a Propshaft dev-perf win.

- **Read-only "CSS" inspector panel** — shipped via `Lookbook.add_panel("css",
…)` in a dev-guarded initializer (`config/initializers/lookbook_panels.rb`).
  `DesignCssPanel` maps `Yui::ButtonComponentPreview` → `design/button.css`
  (dasherised), with a shared fallback for primitives whose rules sit in a layer
  file (typography / layout / field). Rendered read-only + highlighted; the
  `"*"` in `drawer_panels` slots it beside Source/Notes/Params with no extra
  `preview_inspector` config.

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
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
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

#### Retiring the scaffold `spec/views/` layer

`spec/views/` held ~29 `type: :view` template specs (`current_teams/{locations,
members,memories,pictures,weblinks}` CRUD, plus bits of `teams` / `users`).
They are **Rails scaffold output, partially and unevenly upgraded** — loose
`assert_select "article"` / `rendered.include?("Name")` assertions, a
`Rails::VERSION` ternary, commented-out `# TODO` blocks. Almost everything they
check is already covered _better_ by the request specs (which render the same
view through the real controller + routing + auth + layout and assert real
data), and the template sweeps in Phases 3–4 would break every `assert_select`
in them for near-zero return.

`spec/views/users/*` and `spec/views/teams/{new,edit,index,show}` were retired
in Phase 3 (`d81d2d9`, `a5d2628`). The rest go in Phase 4.

**Decision: retire this layer.** As each area is swept:

1. **Port the one thing request specs don't cover** — the form-field contract.
   Move the `new` / `edit` specs' `assert_select "form[action=?][method=?]"` +
   `input`/`select`/`textarea[name="…"]` assertions into that resource's
   **request** spec (`GET /new`, `GET /edit` — they currently only assert
   `be_successful`). Request specs can `assert_select` on `response.body`.
2. **Delete** the resource's `spec/views/**/*_spec.rb` files.
3. **`spec/views/design_head_spec.rb` stays** — it is an asset-config guard, not
   a template spec (every `design/*.css` referenced in `_design_head`, `tokens`
   first, `showcase` excluded from the app set). Nothing replaces it.
4. **Keep the one assertion with real value** —
   `spec/views/teams/locations/show*_spec.rb` checks `country_code` → humanised
   name (`"es"` → `"Spain (ES)"`). That logic currently lives **inline in
   `teams/locations/_location.html.slim`**
   (`ISO3166::Country.find_country_by_alpha2(...).iso_short_name`). When that
   partial is swept, extract it to a `Location#country_name` (or a
   `LocationPresenter`) and unit-test _that_; failing an extraction, assert it in
   the `teams/locations` request spec (`response.body` includes `"Spain"`).
   Either way — **not** a `type: :view` spec.

End state: `spec/views/` contains only `design_head_spec.rb`; one less test
layer to maintain, no coverage lost.

### Phase 0 — Foundations & tooling (~1–1.5 days)

- [x] Remove dead `dartsass-rails` setup (§3).
- [x] Add **Prettier + Stylelint** (§4): `package.json` (devDeps only),
      `.stylelintrc.json`, `.prettierignore`, `bin/css_lint` (`-a` to
      auto-correct), a `css` task in the `rake ci` chain, and the
      `actions/setup-node` + `npm ci` step in CI. Run `bin/css_lint -a` once and
      commit the reformat + any rule disables as a standalone commit. (scoped to `example.css`; the legacy
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

- [x] **Namespace**: `Example::` reads as throwaway. Rename the _primitives_ to
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
      declare `@layer tokens, base, layout, typography, components, composed,
showcase;` in `design/tokens.css`, move `example.css` into per-concern /
      per-component files each wrapped in its layer, move the showcase chrome to
      `design/showcase.css` in its own `showcase` layer (loaded only by
      `/example` + Lookbook). Update `_design_head`, the `/example` layout and
      the Lookbook preview layout to the ordered `<link>` list; add the "every
      `design/*.css` is referenced" guard spec. Land the mechanical move as its
      own commit. Point Stylelint (`.stylelintrc.json` glob) and `.prettierignore`
      at the new dir. (17 files; `_design_head` takes `showcase:`; guard in
      `spec/views/design_head_spec.rb`.)

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

- [x] Layouts: add `_design_head`, wrap `main` in `.ex-scope`, add
      `data-area` for the colour override. (`[data-area="team"|"admin"]`
      override `--ex-accent*` in tokens.css; app / team / admin.)
- [x] Nav: … → build a `Yui::Navbar` + `Yui::NavItem` and rewrite the
      component templates against them.
      (`ApplicationNavLinksComponent` / `ApplicationNavActionsComponent` were
      never wired anywhere → deleted rather than converted. The `+ New` /
      Insights menus stay Pico `details.dropdown` until "Interactive".
      **New:** Pico is now `@import`ed into `@layer pico` via
      `app/assets/stylesheets/pico/<theme>.css` so the layered design system
      wins on shared elements; the unpkg CDN branch is dropped; `base.css`
      pins `:root { font-size: 100% }`. All transitional — gone in Phase 6.)
- [x] Chrome: `shared_partials/_flash_notifications` → `Yui::Toast` /
      `Yui::Callout`; scroll-to-top button; `BrowseHeaderComponent` /
      `ManageHeaderComponent` / `manage`/`browse` headers. (`b81f4c6` — the
      checkbox tick was missed there and is folded into the Interactive commit.)
- [x] Interactive: create dedicated Stimulus controllers under a `yui`
      namespace / prefix (e.g. `yui-dropdown`, `yui-modal`, `yui-tabs`) wired to
      `.ex-dropdown` / `Yui::Modal` / `Yui::Tabs` markup. This allows old Pico
      controllers and new Yui controllers to coexist cleanly during migration.
      Retire `details.dropdown` and `dialog > article` Pico idioms on migrated
      components.
      (**Shipped:** `Yui::Menu` + `Yui::MenuItem` + `yui-menu` (replaces Pico
      `details.dropdown`) — the `+ New` and Insights nav menus are converted and
      the `details.dropdown` CSS is gone. `Yui::Modal` + `yui-modal` (native
      `<dialog>`, backdrop-dismiss) and `Yui::Tabs` + `yui-tabs` (ARIA tablist,
      roving tabindex, arrow keys) ship as ready primitives with previews +
      specs. The legacy `modal` controller and its `dialog > article` consumers
      — the 7 `*/edit` views, `PictureLightboxComponent`,
      `ContentVisibilityModalComponent`, `InsightDestroyModalComponent` — and
      the legacy `tabs` controller (`InsightAttachmentManagerComponent`,
      `locations/_form`) keep working and migrate to the `yui-*` primitives with
      their features in Phases 3–4, exactly the coexistence this bullet is for.)
- [x] Once nav + flash are converted, the chrome no longer needs Pico — but
      leave the `pico.*` links until each area's `<main>` is done. (Nav
      (`ce3b05b`) and flash → `Yui::Toast` (`b81f4c6`) are done. The
      `pico/<theme>` + `legacy` `<link>`s stay in all three layouts — every
      `<main>` still renders Pico-styled content until Phases 3–5 land.)
- [x] As each of these components is rewritten, move its template to a sidecar
      `.slim` per the conventions above (the nav components are the heaviest
      inline heredocs in the repo). (Done for every component touched in
      Phase 2: the nav components, `NavNewButtonComponent`,
      `InsightsDropdownComponent`, and all new `Yui::` primitives use sidecar
      `.slim`. No inline heredocs remain in the converted chrome.)

New primitives needed here (not yet in `/example`): `Navbar` ✓, `NavItem` ✓,
`Modal` ✓, `Tabs` ✓, `Menu`/`Dropdown` ✓ (interactive), `Toast` ✓,
`Pagination` (pagy), `Table`, `Breadcrumb`, `EmptyState` (an app one exists —
`EmptyStateComponent` — restyle it). Still open: `Pagination`, `Table`,
`Breadcrumb`, `EmptyState` restyle.

### Phase 3 — Public / `application` layout (~1.5–2 days)

Templates under the default layout: `pages/*`, `searches/*`, `users/*`,
`logins/*`, `registrations/*`, `user_passwords/*`, `email_verifications/*`,
`sessions/*`, `teams/*` (public), `switch_current_teams/*`.

Done in commits `10b71b4` … `a5d2628`:

- [x] **Prep** (`10b71b4`): `<main>` is a centred container (`--ex-container`
      72→90rem for large screens), `.ex-narrow` for forms / single records;
      `EmptyStateComponent` restyled to `.ex-empty-state` composing Yui
      primitives (API unchanged); `_form_validation_errors` → `Yui::Callout`;
      `Yui::FieldComponent` + `YuiFormBuilder` gained `autofocus` /
      `autocomplete` passthrough.
- [x] **Auth + account forms** (`4e35f30`): `sessions` / `registrations` /
      `user_passwords` / `email_verifications` → `Yui::Card` + `YuiFormBuilder` +
      `Yui::Headline` / `Yui::Link`.
- [x] **users / logins / switch_current_teams** (`d81d2d9`): record partials →
      `Yui::Card` + `dl.ex-details`; `button_to` keeps its `<form>` but wears
      `.ex-btn` (`form.button_to` display fix). `Yui::CardComponent` gained
      `id:` / `data:` passthrough so a card can be a Turbo-stream target.
      Retired `spec/views/users/*` (form contract → `users_request_spec`).
- [x] **`<body>` painted** (`8040d58`): `.ex-body` on the three layouts — the
      whole page carries `--ex-paper`, so `main`'s own ground blends in.
- [x] **pages/error** (`ae53e01`) + `design/base.css` safety nets: unclassed
      `<a>` and raw `<img>` inside `.ex-scope` / `.ex-body`, `ul.ex-stack` drops
      markers.
- [x] **The 5 shared components** (`8ad3bc6`): `ExternalLink` / `MapLink` /
      `Device` / `DeviceLocation` / `SearchForm` / `SearchResults` → sidecar
      templates + Yui markup; specs updated.
- [x] **teams/ top-level** (`a5d2628`): index / show / `_team` / form / new /
      edit → `Yui::Card` + `dl.ex-details`. Retired
      `spec/views/teams/{new,edit,index,show}`.

**Deferred to Phase 4** — the record-card cluster (`teams/{chronicles,memories,
locations,thoughts,members,weblinks,pictures}/*` + `pages/show` + `pages/newer`)
renders `article.yournal-card` / `.card-badge` / `.chronicle-timeline-track`
(from `card.css`) plus `BrowseHeaderComponent` / `ChronicleEntryComponent` and
nested insight partials. That is Phase 4's `card.css` port + `Yui::MemoryCard` /
`Yui::ChronicleCard` adoption, and the partials are shared with
`current_teams/*` — so it is one job, done once, for both areas.
Consequently **`pico/amber` cannot drop until Phase 4** (bare `h3`/`h4`/`p`
still live in those partials), and Phase 3's old "drop pico.amber" + "QA"
bullets move there too.

- [x] **Final QA** — full `rake ci` green (1254 examples, 0 failures; the one
      `pending` is a pre-existing `js: true` system spec). Guest render smoke on
      `/login`, `/register`, `/user_password/new`, `/email_verification/new`,
      `/search`, `/users`, the 404 page: all 200 with the expected `.ex-*`
      markup and **no `--pico-*` leakage**. Authenticated paths (`/teams`,
      `/login_records`, `/switch_current_teams`, `users#edit`) are exercised by
      their request specs, all green in the CI run. (No Phase 0 screenshots
      exist; the spec suite is the behavioural net.)

**Phase 3 is closed.** Remaining public-facing work (the record-card cluster,
the feed, `pico/amber` teardown) lives in Phase 4.

### Phase 4 — Records, feed & team workspace (~3–4 days) — **done**

All four sub-sections (Cards & CSS, Forms & specs, Feed & pagination, Teardown)
are complete; `pico/amber` + `pico/green` are gone. Only two soft items remain:
the `actions: false` card previews (`[~]` below) and a manual visual QA pass.

The largest area, and the home of the shared **record-card** vocabulary. Covers
both the public browse views deferred from Phase 3 (`teams/*`) **and** the team
workspace (`current_teams/*`), because they render the same partials:

- `current_teams/{chronicles,memories,thoughts,weblinks,locations,pictures,
members,pages}` — index / show / new / edit / `_form` / `_record`
- `teams/{chronicles,memories,locations,thoughts,members,weblinks,pictures,
pictures_only,pages}` — index / show / `_record` (public, read-only)
- `pages/show` + `pages/newer` (public feed) and `current_teams/pages/show` +
  `newer` (team feed)
- components: `BrowseHeaderComponent`, `ManageHeaderComponent`,
  `ChronicleEntryComponent`, `ChronicleAttachedEntriesFormComponent`,
  `InsightAttachmentManagerComponent`, `ContentVisibilityModalComponent`,
  `InsightDestroyModalComponent`, `InsightsDropdownComponent`,
  `PictureLightboxComponent`, `PictureSelectFieldComponent`

#### Cards & CSS — done (`03a06eb` … `0fa6d1b`)

- [x] **Port `card.css`, de-pico'd** (`03a06eb`): moved to `design/record.css`
      (`@layer composed`), every `var(--pico-*)` → `--ex-*`; dropped from
      `legacy.css` and deleted. (`record.css` was transitional — the following
      commits emptied it; it is gone as of `a7a3e43`.)
- [x] **`_memory` / `_chronicle` → `Yui::Card`** (`3527e78`, + spec fixup
      `6be2831`), then **→ app-level components** (`57c459e`): `MemoryCardComponent`
      / `ChronicleCardComponent` (`ApplicationComponent`, take the record +
      `scope: :browse | :manage`) hold the composition — `Yui::Card` (accent
      gold / accent, `.ex-memory-card` / `.ex-chronicle-card`) + `Yui::Badge` /
      `Yui::Eyebrow` + the scope's `Browse` / `ManageHeaderComponent` + the memo
      / notice + the nested insight partials (via `InsightPartialRendering`).
      The four `teams|current_teams/{memories,chronicles}/_*` partials are now
      one-line `render …Component.new(…)` adapters. Pure `Yui::MemoryCard` /
      `Yui::ChronicleCard` **deleted** — the app components are the single
      source of truth; `/example` and Lookbook render them.
- [~] **Records — refined component previews.** Still on `actions: false`.
      Attempted the guest-user route: with `build_stubbed` records + `team:`
      passed, the card renders through `render_inline`, but the **real Lookbook
      previews controller** (`render_preview`) wires `Authentication` +
      `TeamScope`, so `BrowseHeaderComponent#can_rewrite?` reaches
      `allowed_to?`, whose `authorization_context` calls
      `TeamScope#current_member` → `Member.find_by!` → `RecordNotFound` for the
      guest. Cleanly fixing it means either a non-raising `current_member`
      fallback in the header components (touches shared auth code — deferred by
      §7 to "later") or a stubbed member in the preview controller. Left as-is.
      **New:** `spec/view_components/previews_render_spec.rb` now renders every
      preview example through the real previews controller, so a broken preview
      fails CI (previously Lookbook-only).
- [x] **`.timeline-grid` → `.ex-record-grid`** (`7063601`): new class in
      `design/layout.css`, `repeat(auto-fill, minmax(min(100%, 28rem), 1fr))` —
      1 / 2 / 3 columns responsively, centred by `<main>`'s 90rem container,
      `align-items: start`. Swapped in the 6 feed/index templates.
- [x] **Nested insight partials** (`2d3ead3`, `a7a3e43`, `de77ca1`, `0fa6d1b`):
      chips → `Yui::Tag` (gained `external:` / `id:`); `blockquote.thought-quote`
      → `Yui::Blockquote` (`variant: :card`, gained `id:`); location / weblink
      detail views → `Yui::Card` + `dl.ex-details`, with the inline ISO3166
      lookup extracted to `Location#country` / `#country_name` / `#country_label`
      (unit-tested); `PictureLightboxComponent` rewritten on `Yui::Modal`
      (`yui-modal` controller), `lightbox.css` → `design/lightbox.css` and
      deleted. `legacy.css` is now just `general.css` + `buttons.css`.
      Retired `spec/views/teams/{locations,weblinks}/show`.

#### Feed & pagination — done (`33cd20d` … `632e6b0`)

- [x] Endless-scroll audit vs pagy 43: added the "stops the chain on the last
      page" request spec to the **team** feed (public already had it) and a
      comment at both `- if @pagy.next` guards — a nil `@pagy.next` is the only
      thing that ends the lazy-frame chain.
- [x] Lazy next-page frame now renders an `.ex-feed-loading` row with a
      `Yui::Spinner` (new primitive: `design/spinner.css`, preview, spec,
      `.ex-visually-hidden` a11y util) instead of resolving from an empty frame.
- [x] "Newer posts" banner → `design/feed.css` `.ex-feed-banner` (a terracotta
      Yui pill, now a real `<button>`); the `--pico-*` `.newer-posts-banner` is
      gone from `general.css`. `feed-refresh` still toggles it (specs green).
- [x] Both feed controllers now expose the poll cursor as `@newest_at` (was
      `@newest_published_at` / `@newest_updated_at`), the `check_newer` JSON as
      `latest_at`, and the `newer.html` wrapper as `data-newest-at`.
- [x] `Yui::PaginationComponent` built (numbered pager, injectable `url` proc
      defaulting to `pagy.page_url`, `design/pagination.css`, `chevron-left`
      icon, preview + spec). Not wired anywhere yet — Phase 5 adopts it for the
      admin index lists.

#### Forms & specs — done (`2e9fb51` … `ba6670f`)

- [x] Lean on `YuiFormBuilder` — `current_teams/{thoughts,weblinks,members,
      memories,chronicles,locations,pictures}/_form` all render `Yui::Card` +
      `YuiFormBuilder` now. The old `role="group"` / inline-`grid` tab pickers
      (locations `_form`, the InsightAttachmentManager location drawer) moved
      onto the `yui-tabs` controller with `.ex-tabs` styling.
- [x] Sidecar the template of every component rewritten in this area:
      `InsightAttachmentManagerComponent`, `ChronicleAttachedEntriesFormComponent`,
      `PictureSelectFieldComponent` (each also de-pico'd into a new
      `design/*.css`: `insight-manager`, `attached-entries`, `picture-select`).
- [x] Modals off the legacy `modal` controller onto `Yui::ModalComponent`
      (`yui-modal`): `ContentVisibilityModalComponent`,
      `InsightDestroyModalComponent`, and a new shared
      `PostDestroyModalComponent` for the memory/chronicle two-path destroy
      dialog (replacing the bespoke `dialog` markup in both `edit` templates).
- [x] Retire the remaining `spec/views/**` scaffold specs — all
      `current_teams/{locations,members,memories,pictures,weblinks}` and
      `teams/**` CRUD view specs are gone; each `new`/`edit` form-field
      contract now lives in the matching `spec/requests/*` spec. Only
      `spec/views/design_head_spec.rb` remains.
- [x] `country_code` → `"Spain (ES)"` humanisation extracted to
      `Location#country_name` / `#country_label` and unit-tested in
      `spec/models/location_spec.rb` (not a `type: :view` spec).

Deferred to Phase 6 teardown: `tabs_controller.js` / `modal_controller.js`
are now unreferenced (superseded by `yui-tabs` / `yui-modal`) and can be
deleted. `PictureSelectFieldComponent` is no longer rendered by any view —
a removal candidate.

#### Teardown for this area — done (`3dcca4c`, `e81e7cc`)

- [x] `pico/amber` dropped from `layouts/application`, `pico/green` from
      `layouts/current_team_area`. Last straggler found + converted on the way:
      `current_teams/content_visibility/edit` (the non-JS fallback behind
      `ContentVisibilityModalComponent`) → `Yui::Card` + `YuiFormBuilder`. No
      `var(--pico-*)` remains outside admin. `legacy.css` (general.css /
      buttons.css) and the empty `@layer pico` stay until Phase 6.
- [~] QA: full `rake ci` green (1362 examples, 1 pre-existing pending). The
      **manual** visual pass on `/`, a team feed, chronicle/memory show and the
      lightbox is still outstanding — do it in a browser before merging.

### Phase 5 — Admin / `admin_area` (~1 day) — **done** (`84aeea9` … `e941161`)

- [x] Every `admins/*/{_record,_form,index,new,edit,show}` view → `Yui::Card`
      + `dl.ex-details` + `YuiFormBuilder`, with two shared partials
      (`admins/_team_field`, `admins/_edit_actions`). `Yui::Table` turned out
      **not** to be needed — the admin views are card-per-record, not tabular;
      build it if a real table appears. `YuiFormBuilder` gained `include_blank:`
      / `multiple:` on `select` for the admin `team_id` / `roles` pickers.
- [x] `AdminActionsComponent`, the six `AdminShow*` components and
      `AdminIndexRecordEventsComponent` → sidecar `.slim` (the **last inline
      `slim_template` heredocs in the repo are now gone**). Fixed the
      `strong Event:` text-swallow bug flagged in Phase 0.
- [x] Admin index actions gained `pagy(:offset, …)` + `Yui::PaginationComponent`
      (its first call sites).
- [x] `spec/views/` retired entirely — the `_design_head` guard moved to
      `spec/lib/design_head_spec.rb`.
- [x] `pico/blue` + `legacy/admin` links dropped from `layouts/admin_area`.
- [ ] **Not touched — `admins/memories`** has a controller but **no views**
      (`# TODO: add views`); `/admin/memories` 500s today, pre-existing. The
      admin nav links to it. And `app/views/admins/record_history/index.html.slim`
      renders a `AdminIndexRecordHistoryComponent` that does not exist and has
      no route — dead scaffolding, left in place.

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
- [ ] The Ruby primitives are `Yui::`, but the CSS
      classes and tokens are still `.ex-*` / `--ex-*` (originally "example");
      `.stylelintrc`'s `custom-property-pattern` already accepts both). Now one atomic
      `ex` → `yui` rename (`.ex-` → `.yui-`, `--ex-` → `--yui-`, `.ex-scope` /
      `.ex-body` too) across `design/**`, the `.slim` templates, and the
      component `ex_class` / `ex_token` helpers — a mechanical `git grep -l`
      sweep + one commit.
- [ ] Add a `slim_lint` / grep check that new templates don't reintroduce bare
      unstyled elements or inline `style=`.
- [ ] Add a grep gate: no `<<-SLIM` / bare `<<SLIM` heredocs, and no inline
      `slim_template` over ~5 lines — enforces the Component & template
      conventions for future components.

### Effort summary

| Phase                                                        | Size                                                       |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| 0 — foundations & tooling                                    | ~1–1.5 days ✅                                             |
| 1 — namespace / conventions / CSS split / data / forms       | ~1.5 days ✅                                               |
| 2 — shared chrome + Stimulus                                 | ~2 days ✅                                                 |
| 3 — public layout (auth / account / users / teams-top-level) | ~1.5–2 days ✅ (record-card cluster → Phase 4)             |
| 4 — records, feed & team workspace                           | ~3–4 days ✅ (card previews `[~]`; manual QA pending)      |
| 5 — admin                                                    | ~1 day ✅ (admins/memories still view-less, pre-existing)  |
| 6 — teardown + CSP                                           | ~0.5–1 day                                                 |
| **Total**                                                    | **~11–14 focused days**, shippable at every phase boundary |

---

## 8. Cost of changing a base ViewComponent later

This is the core trade-off of the chosen approach, so it is worth being precise.

### Cheap changes (the reason we chose this)

- **Token change** (`--ex-accent`, `--ex-radius-*`, `--ex-space-*`, a font):
  one edit in `design/tokens.css`, propagates everywhere instantly, themeable,
  verifiable on `/example` + Lookbook in seconds. **Cost: minutes.**
- **Visual change to a primitive's CSS** (button padding, card shadow, input
  border): one rule in that component's `design/*.css`. No template touched.
  Every call site updates. **Cost: minutes to an hour.**
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

- **Discards ~1,650 lines of tuned, reviewed CSS (`design/*.css`) + ~24
  `Yui::` components + the showcase.** Large sunk cost for no functional gain.
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
- **Utility soup in Slim** unless you _also_ wrap everything in ViewComponents —
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
