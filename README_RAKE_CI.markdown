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
rake ci          (bin/mcp_rake ci — chruby-wrapped equivalent)
├─ ci:lint        rubocop · slim-lint · css (stylelint+prettier) · actionlint · bundle-lock
├─ ci:security    brakeman · bundler-audit --update · importmap-audit
├─ ci:checks      zeitwerk · db-doctor · factory-lint · archspec
└─ ci:rspec       full suite, parallel ×4
```

- **The four steps run serially and fail fast.** If `ci:lint` fails, `rake ci`
  stops there — you do not wait for the suite to learn your style is off.
- **Within a step, the gates run in parallel**, output buffered. A step reports
  *every* failure it found at once (fix them in one pass), then aborts the run.
- Ordering is fastest-feedback-first: lint → security → checks → rspec.
- **No local/CI divergence.** Every gate runs the same in both places. Ideas
  that would only make sense on CI are parked under "Refinement ideas for
  later" rather than special-cased now.

---

## Running it

### Locally

```bash
rake ci            # everything, serial-with-parallel-groups, fail-fast
rake ci:lint       # just the linters
rake ci:security   # just the security gates
rake ci:checks     # just the boot/DB integrity gates
rake ci:rspec      # just the suite (parallel ×4)
```

`bin/mcp_rake ci` is the chruby-wrapping wrapper (see [AGENTS.md](AGENTS.md)) and
behaves identically.

Environment knobs:

| Var              | Default           | Effect                                             |
| ---------------- | ----------------- | ------------------------------------------------- |
| `CI_PARALLELISM` | `Etc.nprocessors` | worker count inside each parallel group           |
| `CI_VERBOSE`     | unset             | print output for passing gates too, not just fails |

Prerequisites (all handled by `bin/setup`, except where noted):

- **Ruby + gems** — `bundle install`
- **Node + npm packages** — for `bin/css_lint` (`npm ci`); `bin/setup` runs it
- **PostgreSQL** — for `db:doctor`, `factory_bot:awesome_lint`, `ci:rspec`
- **actionlint** — optional locally (`brew install actionlint`). The gate
  skips with a notice if the binary is absent; CI installs it, so on CI it
  always runs.

### On CI (GitHub Actions)

[.github/workflows/ci_push_pull_main.yml](.github/workflows/ci_push_pull_main.yml)
runs on every push to `main` and every PR targeting `main`. One `tests` job:

1. checkout, `ruby/setup-ruby` (bundler cache), `actions/setup-node` + `npm ci`
2. `libvips` / `libpoppler` for ActiveStorage variants
3. Postgres service container; `db:drop db:create db:migrate` + `parallel:setup[4]`
4. install `actionlint`
5. **`bundle exec rake ci`**

CI runs the exact same task — it only pre-installs `actionlint` so that gate is
never skipped.

---

## The gates

### `ci:lint` — style & format (no DB)

| Gate          | Tool                                  | Checks                                                              |
| ------------- | ------------------------------------- | ----------------------------------------------------------------- |
| `rubocop`     | rubocop + plugins¹                    | Ruby style, lint, Rails/RSpec/Performance/Capybara/FactoryBot idioms |
| `slim_lint`   | slim_lint (`app/` only²)              | Slim template lint                                                |
| `css`         | `bin/css_lint` → stylelint + prettier | `app/assets/stylesheets/design/**/*.css` lint + format-check      |
| `actionlint`  | actionlint binary                     | GitHub workflow YAML: bad expressions, deprecated syntax, shell bugs |
| `bundle_lock` | `bundle lock --check`                 | `Gemfile.lock` satisfies `Gemfile` (no un-committed dependency drift) |

¹ `rubocop-rails`, `-rspec`, `-rspec_rails`, `-capybara`, `-factory_bot`,
`-faker`, `-performance`, `-rake` (see [.rubocop.yml](.rubocop.yml)).
² Scoped to `app/` so `vendor/bundle/**/*.slim` is never walked on CI.

### `ci:security` — known-vulnerability & static analysis

| Gate              | Tool                          | Checks                                                              |
| ----------------- | ----------------------------- | ----------------------------------------------------------------- |
| `brakeman`        | brakeman (**new gem**)        | Rails static security: SQLi, XSS, `html_safe`, mass-assignment, open redirect, SSRF, unsafe `send`, CSRF gaps |
| `bundler_audit`   | `bundler-audit check --update`| Ruby gems with known CVEs. Refreshes the advisory DB every run, locally and on CI. |
| `importmap_audit` | `bin/importmap audit`         | Pinned JavaScript packages with known advisories                  |

Triaged / not-applicable findings are enumerated in
[config/bundler-audit.yml](config/bundler-audit.yml) and `config/brakeman.ignore`
rather than silenced globally.

### `ci:checks` — integrity that needs the app to boot

| Gate           | Tool                       | Checks                                                                                |
| -------------- | -------------------------- | ----------------------------------------------------------------------------------- |
| `zeitwerk`     | `rails zeitwerk:check`     | every file eager-loads; constant ↔ path naming is correct                           |
| `db_doctor`    | active_record_doctor       | unindexed FKs, missing FKs, extraneous indexes, boolean presence, mismatched column types, … (dev DB — see [.active_record_doctor](.active_record_doctor)) |
| `factory_lint` | `factory_bot:awesome_lint` | every factory + trait builds                                                        |
| `archspec`     | archspec                   | clean-architecture / layering rules ([Archspec.rb](Archspec.rb))                    |

Each gate is shelled out as its own `bundle exec rake …` so the group
parallelises cleanly without sharing an ActiveRecord connection or a
half-eager-loaded constant table.

### `ci:rspec` — the suite

A thin alias for the existing `rspec` task: `parallel_rspec -n 4 spec/`. Named
`ci:rspec` for symmetry with the other steps; `rake rspec` still works.

---

## Refinement ideas for later

Not built now — either genuinely future work, or something that would only pay
off on CI (which this suite deliberately avoids for now to keep one behaviour
everywhere).

| Idea                                    | Rationale / trigger                                                                                                  |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Schema-drift gate** (`db:migrate` + `git diff --exit-code db/schema.rb`) | Catches a migration that was not checked in, or a stale `schema.rb`. Only sensible as a CI-only strict check — a WIP migration must not block an unrelated local `rake ci`. |
| **Production-boot smoke** (`RAILS_ENV=production … rails runner 'Rails.application.eager_load!'`) | Catches missing prod config before deploy. Needs a dummy `SECRET_KEY_BASE`; CI-only. Park until secrets handling is settled. |
| **Secret scanning**                     | GitHub native *Secret scanning + Push protection* (repo setting) vs a `gitleaks` step. Native is zero-maintenance; leaning native + a `gitleaks` pre-commit hook. |
| **N+1 query gate** (`prosopite`)        | Wrap request/system specs; land in *warn* mode, flip to `raise` area-by-area (feed, timelines, insight show) as each is de-N+1'd so we never ship a wall of failures. |
| **Accessibility gate** (`axe-core-rspec`) | `be_axe_clean` smoke on ~5 key pages, widening as the Warm-Editorial migration ([TODO_UI_DESIGN.md](TODO_UI_DESIGN.md)) settles each area. |
| **`zizmor`**                            | GitHub Actions security auditor (permissions, injections, unpinned actions). Run after the workflow-hardening pass so the baseline is clean. |
| **Workflow hardening**                  | Pin `actions/*` to commit SHAs, add `permissions: { contents: read }`, `persist-credentials: false`. |
| **`i18n-tasks health`**                 | Locale files are thin today. Add when i18n coverage grows enough that missing / unused keys are a real risk. |
| **CI job split** (`lint` / `security` / `test` as parallel GHA jobs) | Only wins once suite time ≫ per-job setup (~40 s bundle + ~20 s DB). Not true yet — one job is faster wall-clock. Revisit if `rake ci` passes ~3 min. |
| **`rubocop --format github` annotations** | Inline PR annotations; needs the harness to surface a machine-readable format alongside the buffered text. Cosmetic. |

---

## Omitted on purpose

| Tool                            | Why not (for now)                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **CodeQL**                      | Minutes per run, needs GHAS or a public repo. The value over brakeman + bundler-audit + importmap-audit is marginal at this size. |
| **SimpleCov / coverage floor**  | Coverage numbers drive box-ticking more than they catch bugs; a floor becomes a maintenance tax. Revisit only if regressions start slipping through. |
| **strong_migrations**           | No production data yet, so "unsafe migration" has no teeth. Add the day before / after go-live. |
| **Dependabot**                  | Manual, batched dependency bumps are fine here; automated PR noise is not worth it. `bundler-audit` + `importmap audit` already flag anything *dangerous*. |
| **erb_lint**                    | Slim-first codebase. The remaining `.erb` is scaffold view-spec cruft being retired in Phase 3–4. |
| **mutant (mutation testing)**   | Hours-long; only pays off on small, critical, stable library code. Never a PR gate. |
| **License compliance scanning** | Small, well-understood dependency set. `dependency-review-action` would cover the PR case if it ever matters. |
| **Cross-browser system specs**  | Headless Chrome only. A browser matrix triples system-spec cost for little real-world coverage. |

---

# Implementation plan

Branch: `quality-gates` (off `main`). Small commits, at least one per numbered
step; every commit pushed to `origin/quality-gates`. Commit messages end with
the project's `Co-Authored-By` trailer.

## Phase 0 — this document

- **0.1** Add `README_RAKE_CI.markdown`. Commit, push branch.
- **0.2** Fold in review feedback: `bundler-audit` always `--update`; no CI-only
  gates (schema-drift → "Refinement ideas"); add `ci:rspec`. Commit, push.

## Phase 1 — namespaced tasks + parallel harness

Same gates as today, regrouped and parallelised, **plus** `brakeman`,
`actionlint`, `bundle lock --check`. No behavioural regression.

### 1.1 — extract CI wiring into `lib/tasks/ci.rake`

- New file **`lib/tasks/ci.rake`** holds `namespace :ci`, `task ci:` and
  `task default:`. The `Rakefile` keeps the shared setup (`RUBYOPT=-W0`,
  `load_tasks`, the dev/test guard) and the individual task *definitions* it
  already owns (`rspec`, `db:doctor`, `archspec`, `factory_bot:*`,
  `RuboCop::RakeTask`, `SlimLint::RakeTask`, the `css` task, `Bundler::Audit`).
- `lib/tasks/ci.rake` loads via `Rails.application.load_tasks`, so it sees those
  definitions. Guard its body with the same
  `if %w[development test].include?(Rails.env)` check.
- This commit is a pure move: `task ci:` still points at the current flat list.
  `rake ci` output unchanged. Verify, commit, push.

### 1.2 — the parallel-group helper + its spec

- **Spec first** (`spec/lib/ci_gate_spec.rb`): `CIGate.run_group` returns `true`
  when every command exits 0, `false` otherwise; buffers and prints each gate's
  combined output; prints failures (and, with `CI_VERBOSE`, successes);
  respects `CI_PARALLELISM`. Drive it with `true` / `false` / `echo` commands.
- **`lib/tasks/support/ci_gate.rb`** (plain Ruby; `require`d from `ci.rake`, not
  autoloaded — add `lib/tasks` to `config.autoload_lib(ignore:)` if `lib` is on
  the autoload path):
  - `Parallel.map(gates.to_a, in_threads: [parallelism, gates.size].min)` —
    threads, because each gate is a subprocess (`Open3.capture2e`); IO-bound,
    GVL released on `wait`, no fork cost, no result marshalling.
  - Each gate: `Open3.capture2e({ "BASH_ENV" => nil }, *argv, chdir: Rails.root)`.
    `BASH_ENV=` is mandatory — a personal `BASH_ENV` (chruby auto-switch) is
    otherwise re-sourced by every child bash (the asdf `node` shim included) and
    floods stderr with Bundler warnings under `bundle exec`. Rescue
    `Errno::ENOENT` etc. into a failed result.
  - Buffer everything; print in **declared order**: a `✓ / ✗ name  1.2s` line
    per gate, then a `── name ──` block with captured output for each failure
    (all gates under `CI_VERBOSE`). Footer:
    `ci:lint — 4 ✓  1 ✗  (2.4s)`.
  - Return `results.all?(&:ok)`; caller does `exit(1) unless ok`, which Rake
    turns into a clean non-zero exit that stops the `ci` chain.
- `gem "parallel"` added explicitly to `:development, :test` (today it is only a
  transitive dep of `parallel_tests`).

### 1.3 — `bin/actionlint` wrapper

- New **`bin/actionlint`** (bash, `unset BASH_ENV`, `set -eo pipefail`): if
  `actionlint` is on `PATH`, `exec` it from the repo root (it defaults to
  linting `.github/workflows/`); else print
  `actionlint not installed — skipping (brew install actionlint)` to stderr and
  `exit 0`.

### 1.4 — `ci:lint`

- Carry the `bin/lint_css` → **`bin/css_lint`** rename here (with the `-a` /
  `autocorrect` flag folding in `bin/fix_css`, and the `unset BASH_ENV` fix).
  This mirrors the same change on `yui-design`; whichever merges first, the
  other reconciles trivially (identical content).
- Define `task "ci:lint"` (`# rubocop:disable Rails/RakeEnvironment`):

  ```ruby
  exit(1) unless CIGate.run_group("lint", {
    "rubocop"     => %w[bundle exec rubocop --no-server],
    "slim_lint"   => %w[bundle exec slim-lint app],
    "css"         => %w[bin/css_lint],
    "actionlint"  => %w[bin/actionlint],
    "bundle_lock" => %w[bundle lock --check],
  })
  ```

- Not yet in the `ci` chain — run `rake ci:lint` directly to verify. Commit, push.

### 1.5 — `ci:security` + brakeman

- Add `gem "brakeman", require: false` to `:development, :test`; `bundle install`;
  commit the `Gemfile.lock` change here.
- Run `bundle exec brakeman` once. If it finds pre-existing warnings, generate
  `config/brakeman.ignore` (`brakeman -I`) with each entry triaged in a comment;
  otherwise commit an empty `{}` so the file exists.
- The gate calls brakeman directly (not the `bin/brakeman` binstub, which
  unshifts a rubygems.org `--ensure-latest` round-trip):
  `%w[bundle exec brakeman --quiet --no-pager --no-progress --exit-on-warn]`.
- Define `task "ci:security"`:

  ```ruby
  exit(1) unless CIGate.run_group("security", {
    "brakeman"        => %w[bundle exec brakeman --quiet --no-pager --no-progress --exit-on-warn],
    "bundler_audit"   => %w[bin/bundler-audit check --update],
    "importmap_audit" => %w[bin/importmap audit],
  })
  ```

- Verify `rake ci:security`. Commit, push.

### 1.6 — `ci:checks`

- Define `task "ci:checks"`:

  ```ruby
  exit(1) unless CIGate.run_group("checks", {
    "zeitwerk"     => %w[bundle exec rake zeitwerk:check],
    "db_doctor"    => %w[bundle exec rake db:doctor],
    "factory_lint" => %w[bundle exec rake factory_bot:awesome_lint],
    "archspec"     => %w[bundle exec archspec check],
  })
  ```

- `db_doctor` runs against the **dev** DB (its existing behaviour); the other
  three need no DB or use the test DB. No shared-DB race, so no serial pre-step.
- Verify `rake ci:checks`. Commit, push.

### 1.7 — `ci:rspec` + rewire the top-level task

```ruby
task "ci:rspec" => :rspec           # thin alias for symmetry

task ci: %w[ci:lint ci:security ci:checks ci:rspec]
task default: :ci
```

- Delete the old flat `zeitwerk:check rubocop slim_lint css … bundle:audit` list.
- `bundle:audit:update` / `bundle:audit` now live inside `ci:security`.
- Full `rake ci` run — confirm each step fails fast and the parallel groups
  report all failures. Commit, push.

### 1.8 — align `config/ci.rb`

- The Rails-8 `bin/ci` runner in [config/ci.rb](config/ci.rb) is currently dead
  (GHA calls `rake ci`). Update its steps to `bin/rake ci:lint` / `ci:security` /
  `ci:checks` / `ci:rspec` so `bin/ci` stays a usable alternative runner. Commit,
  push.

### 1.9 — GitHub Actions: install actionlint

- Add one step before **Run rake:ci** that installs `actionlint` (official
  `download-actionlint.bash`, or a pinned release download) and puts it on
  `PATH`. No other workflow change (hardening is a "Refinement idea").
- Commit, push. Draft PR now exercises the full task on real infra.

### 1.10 — docs

- Replace the "still looks like the flat list" note at the top of this file with
  the real task; refresh timings once measured on CI. Update `bin/setup` /
  [README.md](README.md) hints that mention `rake ci` internals. Commit, push.

### Phase 1 verification

For each gate, deliberately introduce a failure (a style nit; a `raw` in a view;
an entry in `config/bundler-audit.yml` that unignores a real advisory, or a
pinned bad gem; a table column with no index; a broken workflow expression) and
confirm: (a) the owning step fails, (b) later steps do not run, (c) sibling
gates in the same step still all report. Revert each.

## Later phases

Everything else — N+1, a11y, schema-drift, prod-boot, secret scanning, workflow
hardening, job split — is captured in **Refinement ideas for later** above, to be
picked up as separate branches when their trigger conditions are met.

## Risks & open questions

- **`rake ci:lint` still boots Rails.** `lib/tasks/*.rake` only load via
  `Rails.application.load_tasks`, so any `rake` invocation pays ~2–3 s of boot
  even for pure linters. Acceptable (amortised, once per run).
- **Parallel boots on the GHA runner.** `ci:checks` runs up to 4 `bundle exec
  rake` subprocesses, each booting Rails (~350 MB). Peak ~1.5 GB on a 16 GB
  runner — fine. Cap with `CI_PARALLELISM` if a smaller runner is used.
- **`db:doctor` is triple-nested** (`rake db:doctor` shells
  `RAILS_ENV=development rake active_record_doctor`). Slow-ish; leave as-is
  unless `ci:checks` becomes the bottleneck, then call `ActiveRecordDoctor`
  in-process.
- **`bundle lock --check` and the network.** If it turns out to require a
  remote source check and is flaky offline, drop it from `ci:lint` (it is the
  least load-bearing gate — `ruby/setup-ruby` already largely enforces lock
  freshness on CI).
- **brakeman baseline.** If the first run surfaces many warnings, phase 1.5
  grows a triaged `config/brakeman.ignore` rather than a scramble of fixes.
- **actionlint locally.** Optional + graceful-skip means a local `rake ci` can
  be greener than CI. Documented; `bin/setup` could `brew install actionlint`
  on macOS as a convenience.
- **`bin/css_lint` rename** collides in spirit with `yui-design`. Content is
  identical on both branches, so the merge is a no-op; flagged so nobody is
  surprised.
