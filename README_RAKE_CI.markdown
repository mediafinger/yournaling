# Rake CI — quality gates

`rake ci` is the single entry point for every automated quality gate in this
repo. The same task runs locally and on GitHub Actions, so "green locally" means
"green on CI".

This document is both the **reference** for the gate suite (top half) and the
**implementation plan** for building it on the `quality-gates` branch (bottom
half). Until the plan lands, the live task still looks like the flat list in
[Rakefile](Rakefile):

```ruby
task ci: %w[zeitwerk:check rubocop slim_lint css factory_bot:awesome_lint
            db:doctor rspec archspec bundle:audit:update bundle:audit]
```

---

## At a glance

```
rake ci
├─ ci:lint        rubocop · slim-lint · css (stylelint+prettier) · actionlint · bundle-lock
├─ ci:security    brakeman · bundler-audit · importmap audit
├─ ci:checks      zeitwerk · db:doctor · factory-lint · archspec   (+ schema-drift, CI only)
└─ rspec          full suite, parallel ×4   (+ N+1 and a11y assertions, phased in)
```

- **The four steps run serially and fail fast.** If `ci:lint` fails, `rake ci`
  stops there — you do not wait for the suite to learn your style is off.
- **Within a step, the gates run in parallel**, output buffered. A step reports
  *every* failure in that step at once (fix them in one pass), then aborts the
  run.
- Ordering is fastest-feedback-first: lint (~10 s) → security (~10 s) →
  checks (~15 s) → rspec (~25 s).

---

## Running it

### Locally

```bash
rake ci            # everything, serial-with-parallel-groups, fail-fast
rake ci:lint       # just the linters
rake ci:security   # just the security gates
rake ci:checks     # just the boot/DB integrity gates
bin/rspec          # or: bundle exec rake rspec   (parallel suite)
```

Environment knobs:

| Var                | Default            | Effect                                             |
| ------------------ | ------------------ | -------------------------------------------------- |
| `CI_PARALLELISM`   | `Etc.nprocessors`  | worker count inside each parallel group            |
| `CI_VERBOSE`       | unset              | print output for passing gates too, not just fails |
| `CI`               | unset locally      | enables the CI-only gates (see below)              |

Prerequisites (all handled by `bin/setup`, except where noted):

- **Ruby + gems** — `bundle install`
- **Node + npm packages** — for `bin/css_lint` (`npm ci`); `bin/setup` runs it
- **PostgreSQL** — for `db:doctor`, `factory_bot:awesome_lint`, `rspec`
- **actionlint** — optional locally (`brew install actionlint`). The gate
  skips with a notice if the binary is absent; CI installs it.

### On CI (GitHub Actions)

[.github/workflows/ci_push_pull_main.yml](.github/workflows/ci_push_pull_main.yml)
runs on every push to `main` and every PR targeting `main`. One `tests` job:

1. checkout, `ruby/setup-ruby` (bundler cache), `actions/setup-node` + `npm ci`
2. `libvips` / `libpoppler` for ActiveStorage variants
3. Postgres service container; `db:drop db:create db:migrate` + `parallel:setup[4]`
4. install `actionlint`
5. **`bundle exec rake ci`** — with `CI=true`, so the CI-only gates are active

CI runs the exact same task; it only adds the gates that are too slow or too
noisy to want on every local run (next section).

---

## The gates

### `ci:lint` — style & format (no Rails boot, no DB)

| Gate         | Tool                        | Checks                                                                 |
| ------------ | --------------------------- | --------------------------------------------------------------------- |
| `rubocop`    | rubocop + plugins¹          | Ruby style, lint, Rails/RSpec/Performance/Capybara/FactoryBot idioms  |
| `slim_lint`  | slim_lint (`app/` only²)    | Slim template lint                                                    |
| `css`        | `bin/css_lint` → stylelint + prettier | `app/assets/stylesheets/design/**/*.css` lint + format-check |
| `actionlint` | actionlint binary           | GitHub workflow YAML: bad expressions, deprecated syntax, shell bugs  |
| `bundle`     | `bundle lock --check`       | `Gemfile.lock` satisfies `Gemfile` (no un-committed dependency drift) |

¹ `rubocop-rails`, `-rspec`, `-rspec_rails`, `-capybara`, `-factory_bot`,
`-faker`, `-performance`, `-rake` (see [.rubocop.yml](.rubocop.yml)).
² Scoped to `app/` so `vendor/bundle/**/*.slim` is never walked on CI.

### `ci:security` — known-vulnerability & static analysis

| Gate              | Tool                        | Checks                                                                             |
| ----------------- | --------------------------- | --------------------------------------------------------------------------------- |
| `brakeman`        | brakeman (**new gem**)      | Rails static security: SQLi, XSS, `html_safe`, mass-assignment, open redirect, SSRF, unsafe `send`, CSRF gaps |
| `bundler_audit`   | bundler-audit               | Ruby gems with known CVEs (advisory DB); `--update` on CI, cached DB locally      |
| `importmap_audit` | `bin/importmap audit`       | Pinned JavaScript packages with known advisories                                  |

Triaged/irrelevant findings are enumerated in `config/bundler-audit.yml` and
`config/brakeman.ignore` rather than silenced globally.

### `ci:checks` — integrity that needs the app to boot

| Gate            | Tool                          | Checks                                                                     |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| `zeitwerk`      | `rails zeitwerk:check`        | every file eager-loads; constant ↔ path naming is correct                 |
| `db_doctor`     | active_record_doctor          | unindexed FKs, missing FKs, extraneous indexes, boolean presence, mismatched column types, … (dev DB — see [.active_record_doctor](.active_record_doctor)) |
| `factory_lint`  | `factory_bot:awesome_lint`    | every factory + trait builds                                             |
| `archspec`      | archspec                      | clean-architecture / layering rules ([Archspec.rb](Archspec.rb))         |
| `schema_drift`  | `db:migrate` + `git diff --exit-code db/schema.rb` | **CI only** — schema.rb is committed and matches the migrations |

Each boot-heavy gate is shelled out as its own `bundle exec rake …` so the
group parallelises cleanly without sharing an ActiveRecord connection or a
half-eager-loaded constant table.

### `rspec` — the suite

Unchanged mechanically: `parallel_rspec -n 4 spec/`. Two assertion-level gates
are folded in during phase 2 (they are not separate steps — they make specs
fail):

- **N+1 queries** — `prosopite` around request/system specs.
- **Accessibility** — `axe-core-rspec` smoke assertions on a handful of key
  pages (feed, memory show, chronicle show, sign-in, settings).

---

## CI-only gates

Active only when `CI=true`, because they are slow, need the network, or need
production-ish secrets that are annoying to reproduce locally:

| Gate                    | Why not local                                                                 |
| ----------------------- | --------------------------------------------------------------------------- |
| `bundler-audit --update`| Fetches `ruby-advisory-db` from GitHub on every run. Locally audits the cached copy. |
| `schema_drift`          | A WIP migration or an intentionally-uncommitted `schema.rb` during feature work should not block an unrelated `rake ci`. Locally the gate just runs `db:migrate` and warns. |
| `prod_boot` (phase 2)   | `RAILS_ENV=production … rails runner 'Rails.application.eager_load!'` — needs a dummy `SECRET_KEY_BASE`; catches missing prod config before deploy. |
| Secret scan (phase 3)   | Full-history scan is slow; local devs get a fast diff-only pre-commit hook instead. |

Everything else runs identically in both places.

---

## Planned — not enabled yet

| Item                              | Rationale / trigger                                                                                     |
| --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **prosopite → raise mode**        | Land in *warn* mode (logs N+1s, does not fail). Flip to `raise` area-by-area as each is de-N+1'd, so we never ship a wall of failures. |
| **axe-core-rspec expansion**      | Start with ~5 smoke pages; widen coverage as the Warm-Editorial migration (see [TODO_UI_DESIGN.md](TODO_UI_DESIGN.md)) settles each area. |
| **`prod_boot` smoke**             | Needs `SECRET_KEY_BASE_DUMMY=1` to work; if prod boot pulls real credentials, defer until secrets handling is sorted. |
| **Secret scanning**               | Decide: GitHub native *Secret scanning + Push protection* (repo setting) vs `gitleaks` CI step. Native is zero-maintenance; gitleaks is portable. Leaning native + a `gitleaks` pre-commit hook. |
| **`zizmor`**                      | GitHub Actions security auditor (permissions, injections, unpinned actions). Runs after workflow hardening lands so the baseline is clean. |
| **`i18n-tasks health`**           | Locale files are thin today. Add when i18n coverage grows enough that missing/unused keys are a real risk. |
| **CI job split** (`lint` / `security` / `test` as parallel GHA jobs) | Only wins once suite time ≫ per-job setup (~40 s bundle + ~20 s DB). Not yet true here — one job is faster wall-clock. Revisit if `rake ci` passes ~3 min. |
| **Deterministic `rubocop --format github`** annotations | Nice PR inline annotations; needs the harness to surface a machine-readable format from the buffered output. Low effort, cosmetic. |

---

## Omitted on purpose

| Tool                | Why not (for now)                                                                                          |
| ------------------- | ------------------------------------------------------------------------------------------------------- |
| **CodeQL**          | Minutes per run, needs GHAS or a public repo. The value over brakeman + bundler-audit + importmap-audit is marginal at this size. |
| **SimpleCov / coverage floor** | Coverage numbers drive box-ticking more than they catch bugs; a floor becomes a maintenance tax. Revisit only if regressions start slipping through. |
| **strong_migrations** | No production data yet, so "unsafe migration" has no teeth. Add the day before / after go-live. |
| **Dependabot**      | Manual, batched dependency bumps are fine for a solo/small project; automated PR noise is not worth it. `bundler-audit` + `importmap audit` already flag anything *dangerous*. |
| **erb_lint**        | Slim-first codebase. The remaining `.erb` is scaffold view-spec cruft being retired in Phase 3–4. |
| **mutant (mutation testing)** | Hours-long; only pays off on small, critical, stable library code. Never a PR gate. |
| **License compliance scanning** | Small, well-understood dependency set. `dependency-review-action` would cover the PR case if it ever matters. |
| **Cross-browser system specs** | Headless Chrome only. A browser matrix triples system-spec cost for little real-world coverage. |

---

# Implementation plan

Branch: `quality-gates` (off `main`). One commit per numbered step, commit
messages ending with the project's `Co-Authored-By` trailer. Push after the
first commit; open a draft PR early.

## Phase 0 — this document

- **0.1** Add `README_RAKE_CI.markdown` (this file). Commit. Push branch.

## Phase 1 — namespaced tasks + parallel harness

The heart of the change. No behavioural regression: the same gates run, plus
`brakeman`, `actionlint`, `bundle lock --check`, `schema_drift`.

### 1.1 — extract CI wiring out of the Rakefile

- New file **`lib/tasks/ci.rake`** — holds `namespace :ci` and the top-level
  `ci` / `default` tasks. `Rakefile` keeps only the shared setup
  (`RUBYOPT=-W0`, `load_tasks`, the dev/test guard) and the individual
  task *definitions* it already owns (`rspec`, `db:doctor`, `archspec`,
  `factory_bot:*`, `RuboCop::RakeTask`, `SlimLint::RakeTask`, the `css` task).
- `lib/tasks/ci.rake` is loaded by `Rails.application.load_tasks`, so it sees
  those definitions. Guard its body with the same
  `if %w[development test].include?(Rails.env)` check.

### 1.2 — the parallel-group helper

- New file **`lib/tasks/support/ci_gate.rb`** (plain Ruby, `require`d from
  `ci.rake`; not autoloaded — lives outside `app/`).
- API:

  ```ruby
  CIGate.run_group("lint", {
    "rubocop"    => %w[bundle exec rubocop --no-server],
    "slim_lint"  => %w[bundle exec slim-lint app],
    "css"        => %w[bin/css_lint],
    "actionlint" => %w[bin/actionlint],
    "bundle"     => %w[bundle lock --check],
  }) # => true if all passed
  ```

- Implementation notes:
  - `Parallel.map(gates, in_threads: [CI_PARALLELISM, gates.size].min)` — threads,
    not processes: every gate is a subprocess (`Open3.capture2e`), so the work
    is IO-bound and the GVL is released during `wait`. No fork cost, no result
    marshalling.
  - Each gate: `out, status = Open3.capture2e({ "BASH_ENV" => nil }, *argv, chdir: root)`.
    `BASH_ENV=` is mandatory — a personal `BASH_ENV` (chruby auto-switch) is
    otherwise re-sourced by every child bash (the asdf `node` shim, …) and
    floods stderr with Bundler warnings under `bundle exec`.
  - Buffer everything; print in **declared order** (not completion order) for
    stable logs: a `✓ / ✗ name  1.2s` line per gate, then a
    `─── name ───` block with captured output for each failure (or all, under
    `CI_VERBOSE`). Footer: `lint: 4 ✓  1 ✗  (2.4s wall)`.
  - Return `results.all?(&:ok)`. The caller does `abort unless ok` — `abort`
    raises `SystemExit(1)`, Rake stops the `ci` chain. That is the "fail fast
    at the step boundary" behaviour.
  - `require "parallel"` explicitly (it is a transitive dep via
    `parallel_tests`; make it a first-class `require`, and add
    `gem "parallel"` to the `:development, :test` group so it is not
    accidentally orphaned).

### 1.3 — `bin/actionlint` wrapper

- New **`bin/actionlint`** (bash): if `actionlint` is on `PATH`, exec it against
  `.github/workflows/`; else print
  `actionlint not installed — skipping (brew install actionlint)` and exit 0.
- CI installs the real binary in a workflow step (`rhysd/actionlint` release
  download, pinned by SHA/version) *before* `rake ci`, so on CI the gate is
  never skipped.

### 1.4 — `ci:lint`

```ruby
desc "Style & format gates (parallel)"
task "ci:lint" do            # no :environment — pure tooling
  abort unless CIGate.run_group("lint", {
    "rubocop"    => %w[bundle exec rubocop --no-server],
    "slim_lint"  => %w[bundle exec slim-lint app],
    "css"        => %w[bin/css_lint],
    "actionlint" => %w[bin/actionlint],
    "bundle"     => %w[bundle lock --check],
  })
end
```

### 1.5 — `ci:security`

- Add `gem "brakeman", require: false` to `:development, :test`; `bundle install`;
  commit the lockfile change with this step.
- New **`bin/brakeman`** already exists as a binstub but unshifts
  `--ensure-latest` (a rubygems.org round-trip). For the gate, call brakeman
  directly: `%w[bundle exec brakeman --no-pager --quiet --format plain]`.
- Seed an empty `config/brakeman.ignore` on first run
  (`brakeman -I` interactive, or hand-write `{}`).
- `bundler_audit` command is `CI` ? `%w[bin/bundler-audit check --update]` :
  `%w[bin/bundler-audit check]`.

```ruby
task "ci:security" do
  audit = ENV["CI"] ? %w[bin/bundler-audit check --update] : %w[bin/bundler-audit check]
  abort unless CIGate.run_group("security", {
    "brakeman"        => %w[bundle exec brakeman --no-pager --quiet --format plain],
    "bundler_audit"   => audit,
    "importmap_audit" => %w[bin/importmap audit],
  })
end
```

### 1.6 — `ci:checks`

- New **`schema_drift`** task (CI-only strict):

  ```ruby
  task "db:schema_drift" => :environment do
    sh({ "BASH_ENV" => nil }, "bundle", "exec", "rake", "db:migrate")
    if ENV["CI"]
      sh "git", "diff", "--exit-code", "--", "db/schema.rb"
    else
      changed = !system("git", "diff", "--quiet", "--", "db/schema.rb")
      warn "⚠  db/schema.rb changed after migrate — commit it" if changed
    end
  end
  ```

- `ci:checks` = serial pre-step (`db:schema_drift`, because it and `db:doctor`
  both touch the **dev** DB and must not race) → then the parallel group:

  ```ruby
  task "ci:checks" => "db:schema_drift" do
    abort unless CIGate.run_group("checks", {
      "zeitwerk"     => %w[bundle exec rake zeitwerk:check],
      "db_doctor"    => %w[bundle exec rake db:doctor],
      "factory_lint" => %w[bundle exec rake factory_bot:awesome_lint],
      "archspec"     => %w[bundle exec archspec check],
    })
  end
  ```

### 1.7 — rewire the top-level task

```ruby
task ci: %w[ci:lint ci:security ci:checks rspec]
task default: :ci
```

- Delete the old flat `zeitwerk:check rubocop slim_lint css … bundle:audit` list.
- Keep `rspec` as the 4th prerequisite (the user's chosen shape); optionally
  add a thin `task "ci:test" => :rspec` alias for symmetry — cosmetic.
- `bundle:audit:update` / `bundle:audit` are now *inside* `ci:security`; remove
  them from the top-level list.

### 1.8 — align `config/ci.rb`

- The Rails-8 `bin/ci` runner in [config/ci.rb](config/ci.rb) is currently dead
  (GHA calls `rake ci`, not `bin/ci`). Update its steps to call the new tasks
  (`bin/rake ci:lint`, `ci:security`, `ci:checks`, `rspec`) so `bin/ci` stays a
  usable alternative, or delete it. Decision at implementation time; lean
  towards updating.

### 1.9 — GitHub Actions: minimal wiring

- Add the `actionlint` install step before `Run rake:ci`.
- No other workflow change in phase 1 (hardening is phase 3).
- Confirm `CI: true` is already in the job `env:` (it is) so the CI-only gates
  switch on.

### 1.10 — docs

- Replace the "still looks like the flat list" note at the top of this file
  with the real task. Update [README.md](README.md) / `bin/setup` hints if they
  mention `rake ci` internals.

**Verification for phase 1:** for each gate, deliberately introduce a failure
(a style nit, a `raw user_input` in a view, a fake CVE in
`config/bundler-audit.yml`'s inverse, a stray column with no index, an
unpinned action) and confirm (a) the owning step fails, (b) later steps do not
run, (c) sibling gates in the same step still all report. Revert.

## Phase 2 — spec-integrated gates

### 2.1 — N+1 (`prosopite`)

- `gem "prosopite"` (+ `gem "pg_query"` for good fingerprinting) in `:test`.
- `spec/support/prosopite.rb`: wrap `:request` and `:system` examples in
  `Prosopite.scan` / `Prosopite.finish`. Start with
  `Prosopite.raise = false` + `Prosopite.rails_logger = true` (warn mode).
- Add a `n_plus_one: :raise` metadata opt-in; flip individual areas (feed,
  timelines, insight show) to raising as they are cleaned.

### 2.2 — Accessibility (`axe-core-rspec`)

- `gem "axe-core-rspec"` in `:test`.
- `spec/system/accessibility_smoke_spec.rb`: `expect(page).to be_axe_clean`
  on feed, memory show, chronicle show, sign-in, settings. Tag `:a11y`.
- Rules tuned to WCAG 2.1 AA; document any temporary `.excluding`.

### 2.3 — Production boot smoke (CI-only)

- Workflow step (or a `ci:prod_boot` task gated on `ENV["CI"]`):
  `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails runner "Rails.application.eager_load!; puts :ok"`.
- If prod boot needs real credentials, park this and note it in "Planned".

## Phase 3 — CI workflow hardening

- **Pin actions to commit SHAs** with `# vX` comments: `actions/checkout@v7`,
  `ruby/setup-ruby@v1`, `actions/setup-node@v7`, the actionlint installer.
- Add top-level `permissions: { contents: read }`; widen per-job only if a
  step needs it.
- `actions/checkout` → `with: { persist-credentials: false }` (nothing pushes;
  `schema_drift`'s `git diff` needs no credentials).
- Add `zizmor` as a gate (or a scheduled workflow) once the above is clean.
- Secret scanning decision (native vs `gitleaks`) + enable Push Protection.

## Commit / rollout strategy

| Commit | Contents |
| ------ | -------- |
| 1 | Phase 0.1 — this document (then **push**, open draft PR) |
| 2 | 1.1–1.2 — `lib/tasks/ci.rake` + `CIGate` helper, `ci` still delegates to the old flat list via a temporary shim |
| 3 | 1.3 — `bin/actionlint` |
| 4 | 1.4 — `ci:lint` |
| 5 | 1.5 — `brakeman` gem + `ci:security` |
| 6 | 1.6 — `db:schema_drift` + `ci:checks` |
| 7 | 1.7–1.8 — flip `task ci:` to the namespaced list, align `config/ci.rb` |
| 8 | 1.9–1.10 — workflow `actionlint` step + doc refresh |
| 9+ | Phase 2 steps, one per gate |
| … | Phase 3 steps |

## Risks & open questions

- **`rake ci:lint` still boots Rails.** `lib/tasks/*.rake` only load via
  `Rails.application.load_tasks`, so any `rake` invocation pays ~2–3 s of boot
  even for pure linters. Acceptable (amortised, once per run). Fixing it means
  restructuring the Rakefile to define the lint namespace before requiring the
  app — deferred, not worth it.
- **Parallel boots on the GHA runner.** `ci:checks` runs up to 4 `bundle exec
  rake` subprocesses, each booting Rails (~350 MB). Peak ~1.5 GB on a 16 GB
  runner — fine. Cap with `CI_PARALLELISM` if a smaller runner is ever used.
- **`db:doctor` is triple-nested** (`rake db:doctor` → shells
  `RAILS_ENV=development rake active_record_doctor`). Slow-ish; leave as-is
  unless the checks group becomes the bottleneck, then call
  `ActiveRecordDoctor` in-process.
- **`schema_drift` vs local WIP.** Made non-fatal locally (warn only); strict
  on CI. If that is still annoying, gate it behind `CI` entirely.
- **`bin/css_lint` name.** The `yui-design` branch renames `bin/lint_css` →
  `bin/css_lint` (with a `-a` autocorrect flag) and adds the `BASH_ENV=` fix.
  If `yui-design` has not merged when phase 1 starts, carry that rename into
  this branch (it is squarely a `rake ci` concern) and reconcile at merge.
- **actionlint locally.** Optional + graceful-skip means a local `rake ci` can
  be greener than CI. Acceptable; documented. `bin/setup` could `brew install
  actionlint` on macOS as a convenience.
- **prosopite noise.** Warm-Editorial view work is in flight; enabling raise
  mode broadly now would fight that. Warn-first, area-by-area flip.
- **Draft PR early** so CI exercises the new task on real infrastructure from
  commit 2, not just locally.
