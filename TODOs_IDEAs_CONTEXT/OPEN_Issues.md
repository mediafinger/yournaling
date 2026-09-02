# Open GitHub Issues — Overview, Effort & Value

Source: <https://github.com/mediafinger/yournaling/issues>
Reviewed: 2026-09-03. Excludes #17 (README), #18 (Markdown), #87 (YUI Design).

Effort scale: **XS** (<½ day) · **S** (½–1 day) · **M** (2–4 days) · **L** (1–2 weeks) · **XL** (multi‑week).
Value scale: 1 (nice‑to‑have) … 5 (critical / blocking a launch).

---

## Summary table

| # | Title | Effort | Value | One‑liner |
|---|-------|:------:|:-----:|-----------|
| 39 | User Authorization | M–L | **5** | Close visibility/authorization gaps: insights team‑only, protect member data, dedicated registration controller, simpler team creation. Partly done. |
| 38 | Improve create and update forms | S–M | 4 | Mark required fields, use proper HTML5 input types, add selects, validate completeness, prefill persisted data. |
| 16 | Implement a waitlist | S–M | 4 | Replace open signup with a waitlist table (name, email, use case, team size, price tolerance) + confirmation email. |
| 19 | Improve image processing | M | 3 | Orientation‑aware variants, EXIF read (suggest date + GPS), strip metadata for privacy, accurate byte‑size detection. |
| 40 | Design User Flows | M (as spec) / XL (to implement) | 3 | Design‑spec issue covering registration, onboarding, teams, reactions, comments, DMs, moderation, free/paid tiers. |
| 44 | Blocking content and users by Moderators | XL | 3 | Full moderation system: `ContentBlock`, `UserBlock`, `ViolationReport`, moderation board. |

---

## #39 — User Authorization  ·  Effort M–L  ·  Value 5

**What it asks for**
- Limit `Insight` visibility (Location, Picture, Thought/Weblink) to team members only.
- Protect user data / member information from unauthorized access.
- Move `User` creation into a dedicated registration controller.
- Streamline team creation.
- Only Memory / Chronicle / Experience / Journey are publicly visible to non‑members.

**Current state (already partially addressed)**
- `RegistrationsController` already exists and is the only signup funnel (routes even block `users#new/create`).
- `action_policy` is in place with a policy per model and a `current_team_scope`.
- `ContentVisibilityPolicy` + `VisibilityConstrainedByParents` / `content_visibility` routes exist.
- `ApplicationPolicy#read?` still returns `guest? == true` — **default read access is open to anyone**, which is the core remaining gap.

**Remaining work**
- Override `read?` in `InsightPolicy`, `LocationPolicy`, `PicturePolicy`, `ThoughtPolicy`, `WeblinkPolicy`, `MemberPolicy`, `UserPolicy` to require team membership (or record ownership for `User`).
- Audit every controller action for a matching `authorize!` / `authorized_scope`.
- Request specs proving guest + non‑member are denied on insights and member/user data.

**Value** — security‑critical; blocks any real launch. Data exposure risk today.

**Caveats / dependencies**
- Touches many policies + controllers; high regression surface → strict TDD, lean on existing request specs.
- Overlaps conceptually with #40 (flows) and #44 (moderation) but does not depend on them.
- "Experience" / "Journey" appear in the domain hierarchy but may not be full models yet — confirm before wiring public visibility for them.

---

## #38 — Improve create and update forms  ·  Effort S–M  ·  Value 4

**What it asks for**
1. Mark required fields visually.
2. Add `<select>` dropdowns where a fixed set of options exists (e.g. visibility state).
3. Use correct HTML5 input types (`date`, `url`, `email`, `number`, …).
4. Verify all necessary fields are present on each form.
5. Optionally render previously persisted object data.

**Current state**
- Slim `_form` partials per resource (`current_teams/{memories,chronicles,pictures,...}`), plus `_form_validation_errors` shared partial.
- YUI design system provides `.yui-*` classes and `Yui::` view components — new form markup should use those.

**Remaining work**
- Build a shared form‑field helper / Yui component (label + required marker + hint + error) and adopt it across `_form` partials.
- Map each attribute to the right input type; convert visibility & enum‑like fields to selects.
- Cross‑check form fields against model `validates` + strong params for completeness.

**Value** — direct UX + data‑quality win, self‑contained, low risk.

**Caveats / dependencies**
- Best done **after / with** the YUI design work (#87) to avoid restyling twice.
- Weblink URL field depends on Markdown decision (#18) only if link rendering changes — otherwise independent.
- Keep accessibility in mind (`aria-required`, `aria-describedby`).

---

## #16 — Implement a waitlist  ·  Effort S–M  ·  Value 4

**What it asks for**
- New table capturing: name, email, use‑case description, team‑size bucket (1 … 20+), price tolerance (free … €20+/mo).
- Automated confirmation email to the applicant.
- Rationale: control server load + filter spam during the first months.

**Current state** — no waitlist code exists.

**Remaining work**
- `WaitlistEntry` model + migration + validations (email format/uniqueness, enums for buckets).
- Public controller + form (`new`/`create`), success page.
- `WaitlistMailer#confirmation` (Letter Opener in dev already configured).
- Decide relationship to `RegistrationsController`: gate signup behind an approved waitlist entry, or run waitlist as a standalone marketing page first.
- Admin visibility via Avo (already in the stack).

**Value** — high for a controlled launch; low technical risk.

**Caveats / dependencies**
- If signup is actually gated, this becomes a dependency of the launch and interacts with #39 registration flow.
- Needs spam protection (honeypot / rate‑limit) or it defeats its purpose.
- GDPR: store consent + purpose, allow deletion.

---

## #19 — Improve image processing  ·  Effort M  ·  Value 3

**What it asks for**
- Detect orientation (landscape / portrait / square) and handle variants accordingly.
- Read EXIF: suggest photo‑taken date and GPS coordinates to the user.
- Strip metadata to produce anonymous images.
- Accurately detect file size in bytes before upload.
- Open to further ideas.

**Current state**
- `Picture` model + `ImageUploadConversionService` resize‑to‑limit + WebP@90 before persist.
- `active_storage_validations` for type/size/dimension; `exifr` gem is commented out in the Gemfile.
- Known TODOs in `picture.rb`: file‑size message hardcoded to 0, aspect‑ratio validation, cropping, `height`/`width` sometimes nil, original file not deleted.

**Remaining work**
- Enable `exifr` (or use `ruby-vips` `get_fields`) to extract DateTimeOriginal + GPS in the service; pass suggestions to the Memory/Chronicle form.
- Ensure the WebP pipeline strips EXIF by default (vips `strip: true` on save).
- Fix byte‑size detection + the `file_size` validation message.
- Orientation helper on `Picture`; orientation‑specific variant methods / cropping.

**Value** — meaningful UX (auto date/location) + real privacy benefit, but not launch‑blocking.

**Caveats / dependencies**
- Stripping metadata and *reading* it must happen in the right order (read from original, strip on output).
- GPS suggestion feeds `Location` insight — coordinate with #39 visibility rules.
- Cropping vs. resize‑to‑limit is a product decision.

---

## #40 — Design User Flows  ·  Effort M (spec) / XL (implementation)  ·  Value 3

**What it is** — a specification issue, not a single deliverable. Covers registration, onboarding, joining teams, content discovery, reactions (👎 hidden from creators), bookmarks, team board/activity feed, DMs (paid can initiate, free can only reply), blocking, moderation escalation (warning → temp ban → permanent), and free/paid tier differences (team size, saved filters, messaging).

**Recommended handling**
- Treat as an umbrella: extract concrete sub‑issues (reactions, bookmarks, team activity board, DMs, tier limits) and close #40 once they exist.
- Prerequisite framing document for #39, #44, and any monetization work.

**Value** — high as alignment/planning; low as a directly shippable unit.

**Caveats / dependencies**
- Overlaps heavily with #44 (moderation) and #39 (visibility). Risk of divergent specs — reconcile them.
- Several features (reactions, bookmarks, DMs, tiers) are net‑new domains not in the codebase.

---

## #44 — Blocking content and users by Moderators  ·  Effort XL  ·  Value 3

**What it asks for**
- `ContentBlock` (moderator, reason, resolution) over Posts + Insights, with defined reason taxonomy.
- `UserBlock` restricting join/create/comment/message, with user notification + right of reply via DM.
- `ViolationReport` by users; reported comments/DMs hidden from the reporter.
- A dedicated moderation board aggregating blocks, reports, and discussion threads.
- Original creators still see their content; other users don't see violations.

**Current state** — none. Also depends on features that don't exist yet (comments, DMs, reactions).

**Remaining work** — three new models + state machines, notification system, moderation role + policies, moderation UI, integration into every content query (visibility filter).

**Value** — important before opening the platform publicly, but premature until comments/DMs and the flows in #40 exist.

**Caveats / dependencies**
- **Depends on** #40 (flow definitions) and on comments/DMs existing.
- Interacts with #39: blocking is another visibility filter layered on policies.
- Large query‑performance consideration: every content listing must exclude blocked items efficiently.

---

## Recommended sequence

1. **#39 User Authorization** — close the open‑read gap first (security).
2. **#16 Waitlist** — unblock a controlled launch; small and independent.
3. **#38 Forms** — do alongside the YUI rollout for UX + data quality.
4. Then #19 (image processing), extract sub‑issues from #40, and defer #44 until comments/DMs exist.

---
---

# Implementation Plans — Top 3

> Added after the first commit of this document. Follow the repo TDD rules
> (`AGENTS.md`): plan → failing specs → implement → `bin/mcp_rubocop -A` → `bin/mcp_rake_ci`.

## Plan 1 — #39 User Authorization

### Goal
Guests and non‑members can read only public Posts (Memory, Chronicle, and
Experience/Journey where modelled). Insights and member/user data are
team‑members‑only. `User` records are self‑only.

### Steps

1. **Characterize current behaviour (failing specs first)**
   - `spec/policies/` : add specs asserting the *desired* rules for
     `PicturePolicy`, `LocationPolicy`, `ThoughtPolicy`, `WeblinkPolicy`,
     `InsightPolicy`, `MemberPolicy`, `UserPolicy` — guest denied `read?`,
     non‑member denied, member allowed.
   - `spec/requests/` : guest GET on a team's pictures/locations/members index
     and show → expect 302/404; public GET on memories/chronicles → still 200.

2. **Introduce a team‑scoped read rule**
   - In `ApplicationPolicy` add a helper:
     ```ruby
     def team_member?
       member.present? && member.user == user && (team.nil? || member.team == team)
     end
     ```
   - Create `TeamMemberReadPolicy` mixin (or a `module`) overriding
     `read?` to `current_team_owns_record? || team_member?` and include it in the
     insight/member policies. Do **not** change `ApplicationPolicy#read?`
     globally yet (keeps Memory/Chronicle public).

3. **Per‑policy overrides**
   - `PicturePolicy`, `LocationPolicy`, `ThoughtPolicy`, `WeblinkPolicy`,
     `InsightPolicy`: `def read? = current_team_owns_record? || with_team_membership`.
   - `MemberPolicy#read?`: same.
   - `UserPolicy`: `read?` → `record == user` (plus admin path if one exists);
     `index?` → false for non‑admins.

4. **Scope the collections**
   - Verify every `index` action uses
     `authorized_scope(Model.all, type: :relation, as: :current_team_scope)`.
   - Confirm `current_team_scope` returns `.none` for guests (it already checks
     `member.present?`).

5. **Controllers**
   - Grep for controller actions lacking `authorize!`/`authorized`. Add
     `verify_authorized` (action_policy's `_verify_authorized` callback) to
     `ApplicationController` in test env to catch omissions.
   - `PublicController`/`pages#show` paths: ensure only public Posts are rendered.

6. **Registration / team creation**
   - Confirm no lingering `users#create` route (already removed).
   - `TeamsController#create`: reduce required inputs to name; auto‑create the
     owner `Member`. Add spec.

7. **Green + regression**
   - `bin/mcp_rubocop -A` on changed files, then `bin/mcp_rake_ci`.
   - Add a regression spec for each hole found.

### Files
`app/policies/*`, `app/controllers/**`, `app/controllers/application_controller.rb`,
`spec/policies/**`, `spec/requests/**`.

### Risks
Broad blast radius; the public `pages#show` feed is the trickiest — it must keep
showing published Memories/Chronicles while hiding insights. Land in small PRs
(one policy group at a time) behind the CI gate.

---

## Plan 2 — #16 Waitlist

### Goal
A public page collects waitlist applications; each applicant gets a confirmation
email; admins review entries in Avo. Signup is **not** gated yet (separate
decision).

### Steps

1. **Model + migration (spec first)**
   - `spec/models/waitlist_entry_spec.rb`: presence of name/email, email format,
     case‑insensitive uniqueness, inclusion for `team_size` and `price_tolerance`.
   - Migration `create_waitlist_entries`:
     `name:string`, `email:string` (unique index, citext or lower index),
     `use_case:text`, `team_size:integer`, `price_tolerance:integer`,
     `confirmed_at:datetime`, timestamps.
   - `WaitlistEntry` model with two `enum`s, `normalizes :email`, validations.
     Reuse `application_record_yid_enabled` if a public id is wanted.

2. **Controller + routes**
   - `resources :waitlist_entries, only: %i[new create]` + a `show`/thank‑you.
   - `WaitlistEntriesController` — no auth; strong params; honeypot field +
     `Rack::Attack`/`rate_limit` (Rails 8) on `create`.
   - `spec/requests/waitlist_entries_spec.rb`: happy path, duplicate email,
     invalid, honeypot triggered.

3. **View**
   - `app/views/waitlist_entries/new.html.slim` using YUI components +
     `_form_validation_errors`. Selects for the two buckets, `type="email"`.

4. **Mailer**
   - `WaitlistMailer#confirmation(entry)` + `spec/mailers`. Enqueue from
     `create` via `deliver_later` (Solid Queue is configured). Set
     `confirmed_at` only if a double‑opt‑in link is added later — v1 just
     acknowledges receipt.

5. **Admin**
   - Register `WaitlistEntry` with Avo (`bin/mcp_rails generate avo:resource`).

6. **Green**
   - `bin/mcp_rubocop -A`, `bin/mcp_rake_ci`.

### Files
`db/migrate/*`, `app/models/waitlist_entry.rb`, `app/controllers/waitlist_entries_controller.rb`,
`app/mailers/waitlist_mailer.rb`, `app/views/waitlist_entries/*`, `app/views/waitlist_mailer/*`,
`config/routes.rb`, `app/avo/resources/*`, `spec/**`.

### Risks / decisions
- Whether/when to gate `RegistrationsController` behind an approved entry — keep
  out of v1 to avoid coupling with #39.
- GDPR: add purpose text + easy deletion; document retention.
- Spam: honeypot + rate‑limit are mandatory, not optional.

---

## Plan 3 — #38 Improve create and update forms

### Goal
Every create/update form marks required fields, uses correct HTML5 input types,
uses selects for fixed option sets, matches model validations, and prefills
persisted values on edit.

### Steps

1. **Shared field component**
   - Add `Yui::FormField` view component (or a `form_field` helper) rendering:
     label, `*` required marker + `aria-required`, hint text, inline error from
     the model, wrapping the actual input yielded by the caller.
   - `spec/view_components/yui/form_field_spec.rb` (Lookbook preview too).

2. **Field‑type audit (one partial at a time)**
   - For each `_form.html.slim` under `app/views/current_teams/*` and
     `app/views/{users,teams,registrations,sessions}`:
     - map each attribute → input type: dates → `date`, weblink URL → `url`,
       email → `email`, counts → `number`.
     - visibility / enum‑like attributes → `<select>` from the model's
       `VISIBILITY_STATES` / enum keys.
     - add `required` where the model validates presence.

3. **Completeness check**
   - Diff each form's fields against the model `validates` list and the
     controller's permitted params. Add any missing field or note why omitted.

4. **Prefill on edit**
   - Ensure `form_with model:` (not `url:`) so values round‑trip; add request
     specs asserting `edit` renders current values in inputs.

5. **Tests**
   - `spec/requests/**` for each resource: `new` shows required markers;
     `edit` prefills; invalid submit re‑renders with errors on the right field.
   - System/Capybara spec for one representative form (memory) covering the
     select + date input.

6. **Green**
   - `bin/mcp_rubocop -A`, `bin/mcp_rake_ci`.

### Files
`app/view_components/yui/form_field.*`, `app/views/**/_form*.slim`,
`app/views/**/edit.html.slim`, `spec/**`.

### Risks / dependencies
- Do this **with or right after** the YUI design rollout (#87/#86) so form
  markup is styled once.
- Keep accessibility (`aria-required`, `aria-describedby` for hints/errors).
- Slim indentation churn — keep PRs per‑resource for reviewability.
