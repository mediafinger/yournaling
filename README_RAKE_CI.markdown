# Rake CI - quality gates

`rake ci` is the single entry point for every automated quality gate in this
repo. The same task runs locally and on GitHub Actions, so "green locally" (usually) means
"green on CI".

## At a glance

```
rake ci                                                             ~40 s
├─ ci:lint     rubocop · slim-lint · css · actionlint               ~03 s
├─ ci:security brakeman · bundler-audit --update · importmap-audit  ~03 s
├─ ci:checks   zeitwerk · db-doctor · factory-lint · archspec       ~04 s
└─ ci:rspec    full test suite (1244 specs), parallel ×4            ~28 s
```

> (Total times from a local run, each step's gates run in parallel, so a step is roughly as slow as its slowest gate.)

- **The four steps run serially and fail fast.** If `ci:lint` fails, `rake ci` stops there
- **Within a step, the gates run in parallel**, output buffered. A step reports *every* failure it found at once (fix them in one pass), then aborts the run.
- Ordering is fastest-feedback-first: lint → security → checks → rspec.
- **No local/CI divergence.** Every gate runs the same in both places.
  - Ideas for other quality gates are listed under _"Refinement ideas for later"_ (some might run on CI only).

> ## When you need faster feedback
> 
> During the development process you probably only want to run the specs that touch code you are working on:
> 
> `bundle exec rspec spec/folder/filename_spec.rb` _adding: `:23` runs only the scope at line 23._
> 
> Before committing or running the whole suite, you might want to run:
> 
> `bundle exec rubocop -a` to auto-correct smaller linter violations in the Ruby code.
>

## The gates

### `rake ci:lint` - style & format (no DB needed)

| Gate         | Tool                                  | Checks                                                               |
|--------------|---------------------------------------|----------------------------------------------------------------------|
| `rubocop`    | rubocop + plugins¹                    | Ruby style, lint, Rails/RSpec/Performance/Capybara/FactoryBot idioms |
| `slim_lint`  | slim_lint (`app/` only²)              | Slim template lint                                                   |
| `css`        | `bin/css_lint` → stylelint + prettier | `app/assets/stylesheets/design/**/*.css` lint + format-check         |
| `actionlint` | actionlint binary                     | GitHub workflow YAML: bad expressions, deprecated syntax, shell bugs |

¹ `rubocop-rails`, `-rspec`, `-rspec_rails`, `-capybara`, `-factory_bot`, `-faker`, `-performance`, `-rake` (see [.rubocop.yml](.rubocop.yml)).  
² Scoped to `app/` so `vendor/bundle/**/*.slim` is never walked on CI.

### `rake ci:security` - known-vulnerabilities & static analysis

| Gate              | Tool                           | Checks                                                                                                        |
|-------------------|--------------------------------|---------------------------------------------------------------------------------------------------------------|
| `brakeman`        | brakeman (**new gem**)         | Rails static security: SQLi, XSS, `html_safe`, mass-assignment, open redirect, SSRF, unsafe `send`, CSRF gaps |
| `bundler_audit`   | `bundler-audit check --update` | Ruby gems with known CVEs. Refreshes the advisory DB every run, locally and on CI.                            |
| `importmap_audit` | `bin/importmap audit`          | Pinned JavaScript packages with known advisories                                                              |

Triaged / not-applicable findings are enumerated in [config/bundler-audit.yml](config/bundler-audit.yml) and [config/brakeman.ignore](config/brakeman.ignore)

### `rake ci:checks` - integrity that needs the app to boot

| Gate           | Tool                       | Checks                                                                                                                                                     |
|----------------|----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `zeitwerk`     | `rails zeitwerk:check`     | every file eager-loads; constant ↔ path naming is correct                                                                                                  |
| `db_doctor`    | active_record_doctor       | unindexed FKs, missing FKs, extraneous indexes, boolean presence, mismatched column types, … (dev DB - see [.active_record_doctor](.active_record_doctor)) |
| `factory_lint` | `factory_bot:awesome_lint` | every factory + trait builds                                                                                                                               |
| `archspec`     | archspec                   | clean-architecture / layering rules ([Archspec.rb](Archspec.rb))                                                                                           |

Each gate is shelled out as its own `bundle exec rake` task so the group parallelises cleanly without sharing an ActiveRecord connection or a half-eager-loaded constant table.

### `rake ci:rspec` - the suite

A thin alias for the existing `rspec` task: `parallel_rspec -n 4 spec/`. Named `ci:rspec` for symmetry with the other steps.  
`rake rspec` still works.

## Run it locally

```bash
rake ci            # everything, serial-with-parallel-groups, fail-fast
rake ci:lint       # just linters for Ruby, CSS, Slim, GHA workflow
rake ci:security   # just security gates for Ruby, Dependencies, Importmaps
rake ci:checks     # just integrity gates for load order, database, factories, architecture boundaries
rake ci:rspec      # the whole test suite with all unit and integration specs (parallel ×4)
```

`bin/mcp_rake ci` is the chruby-wrapping wrapper for AI Agents (see [AGENTS.md](AGENTS.md)) and behaves identically.

ENVs:

| Var              | Default           | Effect                                             |
|------------------|-------------------|----------------------------------------------------|
| `CI_PARALLELISM` | `Etc.nprocessors` | worker count inside each parallel group            |
| `CI_VERBOSE`     | unset             | print output for passing gates too, not just fails |

Prerequisites (all handled by `bin/setup`, except where noted):

- **Ruby + gems** - `bundle install`
- **Node + npm packages** - for `bin/css_lint` (`npm ci`); `bin/setup` runs it
- **PostgreSQL** - for `db:doctor`, `factory_bot:awesome_lint`, `ci:rspec`
- **actionlint** - optional locally (`brew install actionlint`). The gate
  skips with a notice if the binary is absent, CI installs it, so on CI it always runs.

## Run it on GitHub Actions CI 

[.github/workflows/ci_push_pull_main.yml](.github/workflows/ci_push_pull_main.yml) runs on every push to `main` and every PR targeting `main`. One `tests` job:

1. checkout, `ruby/setup-ruby` (bundler cache), `actions/setup-node` + `npm ci`
2. `libvips` / `libpoppler` for ActiveStorage variants
3. Postgres service container; `db:drop db:create db:migrate` + `parallel:setup[4]`
4. install `actionlint`
5. **`CI_VERBOSE=1 bundle exec rake ci`**

CI runs the exact same task - it only pre-installs `actionlint` so that gate is never skipped.

## Refinement ideas for later

Not included (yet). Some will be later, some probably on CI only.

| Idea                                                                                              | Rationale / trigger                                                                                                                                                                                                                  |
|---------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Schema-drift gate** (`db:migrate` + `git diff --exit-code db/schema.rb`)                        | Catches a migration that was not checked in, or a stale `schema.rb`. Only sensible as a CI-only strict check - a WIP migration must not block an unrelated local `rake ci`.                                                          |
| **strong_migrations**                                                                             | No production data yet, so "unsafe migration" has no teeth. Add the day before / after go-live.                                                                                                                                      |
| **Production-boot smoke** (`RAILS_ENV=production … rails runner 'Rails.application.eager_load!'`) | Catches missing prod config before deploy. Needs a dummy `SECRET_KEY_BASE`; CI-only. Park until secrets handling is settled.                                                                                                         |
| **Secret scanning**                                                                               | GitHub native *Secret scanning + Push protection* (repo setting) vs a `gitleaks` step. Native is zero-maintenance; leaning native + a `gitleaks` pre-commit hook.                                                                    |
| **N+1 query gate** (`prosopite`)                                                                  | Wrap request/system specs; land in *warn* mode, flip to `raise` area-by-area (feed, timelines, insight show) as each is de-N+1'd so we never ship a wall of failures.                                                                |
| **Accessibility gate** (`axe-core-rspec`)                                                         | `be_axe_clean` smoke on ~5 key pages, widening as the Warm-Editorial migration ([TODO_UI_DESIGN.md](TODO_UI_DESIGN.md)) settles each area.                                                                                           |
| **`zizmor`**                                                                                      | GitHub Actions security auditor (permissions, injections, unpinned actions). Run after the workflow-hardening pass so the baseline is clean.                                                                                         |
| **Workflow hardening**                                                                            | Pin `actions/*` to commit SHAs, add `permissions: { contents: read }`, `persist-credentials: false`.                                                                                                                                 |
| **`i18n-tasks health`**                                                                           | Locale files are thin today. Add when i18n coverage grows enough that missing / unused keys are a real risk.                                                                                                                         |
| **CI job split** (`lint` / `security` / `test` as parallel GHA jobs)                              | Only wins once suite time ≫ per-job setup (~40 s bundle + ~20 s DB). Not true yet - one job is faster wall-clock. Revisit if `rake ci` passes ~3 min.                                                                                |
| **`rubocop --format github` annotations**                                                         | Inline PR annotations; needs the harness to surface a machine-readable format alongside the buffered text. Cosmetic.                                                                                                                 |
| **Lockfile-drift gate** (`Gemfile.lock` in sync with `Gemfile`)                                   | Bundler 4 dropped `bundle lock --check`, and `bundle check` / `bundle install --frozen` do not reliably fail on drift here. `ruby/setup-ruby` (`bundler-cache: true`) already enforces it on CI. Revisit with a purpose-built check. |


## Omitted on purpose

| Tool                            | Why not (for now)                                                                                                                                          |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **CodeQL**                      | Minutes per run, needs GHAS or a public repo. The value over brakeman + bundler-audit + importmap-audit is marginal at this size.                          |
| **SimpleCov / coverage floor**  | Coverage numbers drive box-ticking more than they catch bugs; a floor becomes a maintenance tax. Revisit only if regressions start slipping through.       |
| **Dependabot**                  | Manual, batched dependency bumps are fine here; automated PR noise is not worth it. `bundler-audit` + `importmap audit` already flag anything *dangerous*. |
| **erb_lint**                    | Slim-first codebase. The remaining `.erb` is scaffold view-spec cruft being retired in Phase 3–4.                                                          |
| **mutant (mutation testing)**   | Hours-long; only pays off on small, critical, stable library code. Never a PR gate.                                                                        |
| **License compliance scanning** | Small, well-understood dependency set. `dependency-review-action` would cover the PR case if it ever matters.                                              |
| **Cross-browser system specs**  | Headless Chrome only. A browser matrix triples system-spec cost for little real-world coverage.                                                            |

## Later phases

Everything else - N+1, a11y, schema-drift, prod-boot, secret scanning, workflow hardening, job split... is captured in **Refinement ideas for later** above, to be implemented when their conditions are met.
