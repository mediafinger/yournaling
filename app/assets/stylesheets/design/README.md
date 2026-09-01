# `design/` — the Warm Editorial stylesheet

The app's design language, split by concern. Plain CSS, served directly by
Propshaft — no build step. See `TODO_UI_DESIGN.md` §4 for the reasoning.

## Files & cascade

`tokens.css` declares the layer order **once**:

```css
@layer pico, tokens, base, layout, typography, components, composed, showcase;
```

Every other file wraps its rules in one of those layers, so the cascade is
fixed by that list and **does not depend on `<link>` order**. `@font-face`
stays unlayered at the top of `tokens.css`.

`pico` is first (lowest priority): during the Pico → design-language migration
the app layouts load `app/assets/stylesheets/pico/<theme>.css`, a one-line
wrapper that `@import`s Pico into `@layer pico` so the design system wins on
elements Pico also styles (`a`, `button`, …). Both the `pico/` wrapper and the
`:root { font-size: 100% }` reset in `base.css` go away in Phase 6.

| Layer        | Files                                                                                                                                |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `tokens`     | `tokens.css` — fonts, colour, type scale, spacing, radii, shadows, motion (`:root` + dark)                                           |
| `base`       | `base.css` — `.ex-scope` / `.ex-body`, box-sizing, `:focus-visible`, `::selection`, reduced-motion                                   |
| `layout`     | `layout.css` — container, stack, cluster, grid, divider                                                                              |
| `typography` | `typography.css` — headings, lead, text, prose, blockquote, eyebrow                                                                  |
| `components` | `button.css` `link.css` `badge.css` `tag.css` `card.css` `field.css` `callout.css` `avatar.css` `figure.css` `icon.css` `navbar.css` `toast.css` `scroll-top.css` `menu.css` `modal.css` `tabs.css` `record-header.css` |
| `composed`   | `memory-card.css` `chronicle-card.css`                                                                                               |
| `showcase`   | `showcase.css` — its own layer, above everything; `/example` + Lookbook only, loaded via `_design_head`'s `showcase: true`           |

Loading order lives in one place: `app/views/shared_partials/_design_head.html.slim`
(one `<link>` per file, `tokens` first). `spec/views/design_head_spec.rb` fails
if a `design/*.css` file is not listed there — **add a new file to that array**.

Each `Yui::` primitive maps to `design/<name>.css` by name
(`Yui::ButtonComponent` → `design/button.css`).

## Fast CSS feedback loop

There is no in-browser editor. Two loops, most-leverage first:

### 1. DevTools Workspace (best for token work)

One-time setup:

1. In Lookbook, open a preview in its own tab (preview toolbar → _open in new
   window_) — or just visit `/lookbook/preview/yui/<name>/<scenario>`.
2. DevTools → **Sources** → **Workspace** (a.k.a. "Filesystem") → **Add folder**
   → pick `app/assets/stylesheets/design/`. Grant write access.
3. DevTools maps the loaded `/assets/design/*.css` to the local files
   (green dot on the file in Sources).

Now edits in the **Styles** pane write straight into the correct `design/*.css`
file on disk. Editing a `:root` token in `tokens.css` re-renders every specimen
instantly. Discard an experiment with `git checkout -- app/assets/stylesheets/design`.

### 2. Editor + auto-reload

Lookbook watches `design/` and reloads the open preview on save, so you can edit
in your editor with no manual refresh. Configured in `config/application.rb`
(`config.lookbook.listen_paths`), backed by the `listen` gem in the
`:development` group.

### Reference: the "CSS" panel

Every Lookbook inspect view has a read-only **CSS** tab (hotkey `c`) showing the
`design/*.css` file for that primitive — no editing, just so the styles are one
click away. Mapping in `config/initializers/lookbook_panels.rb`.
