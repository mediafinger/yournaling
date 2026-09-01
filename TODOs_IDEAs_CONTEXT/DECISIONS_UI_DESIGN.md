# UI Design — decisions log

Companion to `TODO_UI_DESIGN.md`. Records decisions as each is settled during
the rollout, so the reasoning stays traceable after the plan's checkboxes are
ticked.

---

## D1 · Scoping strategy: `.ex-scope` on `<main>` per layout (2026-09-01, Phase 0)

**Decision.** The design language is applied by adding `class="ex-scope"` to the
`<main>` element of each layout — not to `<body>`, and not per-component.

- `example.css` already defines **no global reset and no bare-element rules**;
  every rule is under `.ex-body` / `.ex-scope` or a `.ex-*` class. So a scoped
  `<main>` renders in the new design while the surrounding `<header>` / `<nav>`
  chrome stays on Pico untouched.
- `.ex-body` stays reserved for the standalone `layouts/example` (whole document
  is the design language, no Pico).
- Migration order within a layout: convert every template `<main>` renders →
  then convert that layout's nav / header / flash components → then drop the
  `pico.<colour>` `<link>` from that layout (Phase 2–5).
- Per-area accent: set `data-area="team"` / `data-area="admin"` on `<main>` (or
  `<body>`) and override `--ex-accent*` for `[data-area="…"]` in `example.css`.
  Default stays terracotta. (Implemented in Phase 2.)

**Rejected alternatives.**

| Option | Why not |
|---|---|
| `.ex-body` on `<body>` for every layout | `example.css` sets base type/background on the scope root; on `<body>` it would restyle the still-Pico nav/header and fight `navbar.css` during the whole migration. |
| Per-component opt-in (`.ex-scope` on each converted partial) | Dozens of wrapper divs, fragile nesting, and layout utilities (`.ex-container`, `.ex-stack`) that expect a single scope ancestor would need re-scoping constantly. |
| No scope — make `example.css` global now | Requires deleting Pico first (Phase 6) or accepting two competing full-page resets. Not incremental. |

**Follow-ups:** documented the rule in `Yui::BaseComponent` in Phase 1; layouts
get `.ex-scope` + `data-area` in Phase 2.
