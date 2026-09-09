# Better Bundle

Evaluation of [Gemfile of Dreams: libraries we use to build Rails apps](https://evilmartians.com/chronicles/gemfile-of-dreams-libraries-we-use-to-build-rails-apps)
(Evil Martians) against yournaling's actual stack.

Baseline as of `main` @ 698d766: Rails 8.1, PostgreSQL, Solid Queue/Cache/Cable,
importmap + Hotwire + Slim, ViewComponent + Lookbook, action_policy, `has_secure_password`,
RSpec + FactoryBot + Capybara/Selenium, RuboCop (7 plugins), archspec, active_record_doctor.

Gems from the article that are **already in our Gemfile** are not repeated below — they are the
baseline, not additions: `rails`, `pg`, `puma`, `solid_queue`, `mission_control-jobs`, `pg_search`,
`scenic`, `pagy`, `action_policy`, `view_component`, `lookbook`, `turbo-rails`, `bootsnap`,
`bundler-audit`, `brakeman`, `rubocop-rails`, `rubocop-rspec`, `rspec-rails`, `factory_bot_rails`,
`capybara`, `webmock`, `letter_opener-web`.

---

## 1. Great fit, plan implementation

| Gem | What it does | Why now |
|-----|--------------|---------|
| [cuprite](https://github.com/rubycdp/cuprite) | Capybara driver speaking CDP directly to Chrome; no Selenium/chromedriver | Our JS system specs use only `attach_file` + one `execute_script`, zero `.manage` calls — migration is the `js: true` block in `spec/spec_helper.rb`. Also fixes the dead `page.driver.header` guard on line 33, which silently no-ops under Selenium, so JS specs run with a real Chrome UA while rack_test specs get `"Rails System Test"` |
| [test-prof](https://github.com/test-prof/test-prof) | Test suite profiler + `let_it_be` / `before_all` / factory linting | `Slow_Specs.md` is an open TODO about exactly this. Top offenders are request/system specs that rebuild the same team/user/member graph per example; `before_all` attacks them directly without rewriting assertions |
| [isolator](https://github.com/palkan/isolator) | Raises when non-DB side effects (mail, jobs, HTTP) happen inside a DB transaction | `UserRegistrationService#call` already contains a hand-written comment reasoning about `deliver_later` vs. transaction commit. Isolator turns that reasoning into an automatic dev/test guard — relevant because `create_with_event` / `update_with_event` / `destroy_with_event` wrap everything in transactions |
| [after_commit_everywhere](https://github.com/Envek/after_commit_everywhere) | `after_commit` / `after_rollback` callable from any object, not just AR models | Direct companion to isolator: our service objects (not models) are where side effects live. Replaces the manual `if user.persisted?` ordering in `UserRegistrationService` with an explicit post-commit hook |
| [prosopite](https://github.com/charkost/prosopite) | N+1 query detection with no false positives (unlike Bullet) | Timeline and card feeds fan out over `team_artefacts` and polymorphic `chronicle_entries`; `has_many :chronicles, -> { distinct.reorder(...) }, through:` on five models is a classic N+1 shape. Dev/test only, no runtime cost |
| [with_model](https://github.com/Casecommons/with_model) | Defines throwaway AR models + tables inside a spec file | `Archivable` documents its own gap: *"Missing are specs for the `archive_associated` functionality as the Session model does not have any has_many associations."* That is the with_model use case verbatim. Also applies to `Publishable` and `VisibilityConstrainedByParents` |

---

## 2. Potential improvement in the future

| Gem | What it does | Why later |
|-----|--------------|-----------|
| [strong_migrations](https://github.com/ankane/strong_migrations) | Blocks migrations that lock tables or break rolling deploys | Gemfile comment for `fix-db-schema-conflicts` says "without strong_migrations", so this was a deliberate opt-out. Worth revisiting before the production Solid Stack move in `TODO_DATABASE.md` |
| [store_attribute](https://github.com/palkan/store_attribute) | Typed, cast accessors for keys inside a JSONB column | `teams.preferences` and `users.preferences` are `jsonb default: {}` with only a presence validation. Add when preferences actually hold something |
| [store_model](https://github.com/DmitryTsepelev/store_model) | Maps a JSON column onto a validated model class | Fits `locations.geocoded_address`, `weblinks.preview_snippet` and `record_events.properties`, all currently untyped JSON blobs |
| [capybara-lockstep](https://github.com/makandra/capybara-lockstep) | Syncs Capybara with in-flight JS/AJAX to kill race flakiness | We lazy-load turbo-frames (`card_open_and_rewrite_links_spec.rb` page-2 test, 2.7s). Adopt after cuprite so only one driver variable changes at a time |
| [vcr](https://github.com/vcr/vcr) | Records/replays real HTTP interactions as cassettes | Geocoder + `ChimeraHttpClient` responses are currently hand-stubbed via WebMock; cassettes would keep reverse-geocoding fixtures honest |
| [retriable](https://github.com/kamui/retriable) | Configurable retry with backoff for flaky calls | Geocoding is a third-party network dependency in the Location create path; no retry today |
| [groupdate](https://github.com/ankane/groupdate) | `group_by_day/week/month` with timezone handling | Insight timelines and Blazer dashboards over Ahoy data both want period bucketing |
| [zonebie](https://github.com/alindeman/zonebie) | Randomizes `Time.zone` per test run | We now store `pictures.taken_at` from EXIF plus separate `date` columns and geocode coordinates — timezone bugs are plausible and currently invisible in CI |
| [lograge](https://github.com/roidrage/lograge) | Collapses Rails request logs into one structured line | `gem "logstasher"` sits commented out in the Gemfile, so the intent exists; lograge is the better-maintained equivalent |
| [pghero](https://github.com/ankane/pghero) | Postgres dashboard: slow queries, unused/missing indexes, bloat | Complements Blazer (which we have for ad-hoc SQL) rather than duplicating it |
| [vernier](https://github.com/jhawthorn/vernier) | Modern sampling profiler with thread/GVL visibility | Useful for the `Slow_Specs.md` work and for image-processing hot paths; supersedes stackprof |
| [rack-mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler) | In-page request/SQL timing badge in development | Cheap dev feedback on timeline queries and variant generation |
| [n_plus_one_control](https://github.com/palkan/n_plus_one_control) | RSpec matcher asserting query count stays flat as data grows | Regression net once prosopite has found the existing offenders |
| [ar_lazy_preload](https://github.com/DmitryTsepelev/ar_lazy_preload) | Preloads associations automatically on first access | Genuinely effective, but adds runtime magic; prefer explicit `includes` guided by prosopite first |
| [view_component-contrib](https://github.com/palkan/view_component-contrib) | Sidecar structure, base class and preview helpers for ViewComponent | Our `Yui::` primitives + Lookbook setup is already conventional; contrib is a refactor, not a fix |
| [reactionview](https://reactionview.dev/) | Validates rendered HTML and surfaces view errors | Would catch malformed markup in Slim templates and components; young gem, watch it |
| [premailer-rails](https://github.com/fphilipe/premailer-rails) | Inlines CSS into HTML emails | Only 2 mailers today; matters once transactional mail gets styled |
| [imgproxy-rails](https://github.com/imgproxy/imgproxy-rails) | On-the-fly image transforms via an imgproxy service | Alternative to ActiveStorage variants for a picture-heavy app, but requires running another service — scaling decision, not a current need |
| [flipper](https://github.com/flippercloud/flipper) | Feature flags with an admin UI and multiple backends | Useful once the roadmap features (reactions, comments, reader subscriptions) start shipping incrementally |
| [pay](https://github.com/pay-rails/pay/) | Stripe/Paddle subscriptions and billing for Rails | `TODO.markdown` plans payment history for teams and users, and `user.rb` jokes about charging for short nicknames — this is on the roadmap, just not yet |
| [evil-seed](https://github.com/evilmartians/evil-seed) | Builds anonymized dev seeds from a production dump | No production data worth anonymizing yet; revisit post-launch |
| [data_migrate](https://github.com/ilyakatz/data-migrate) | Versioned data migrations, separate from schema migrations | No `db/data` today; backfills are currently ad-hoc. Worth it at the first real backfill |
| [yabeda](https://github.com/yabeda-rb/yabeda) (+ [puma plugin](https://github.com/yabeda-rb/yabeda-puma-plugin)) | Pluggable app metrics, Prometheus-ready | Only once a metrics backend exists; Ahoy + Blazer cover product analytics, not ops |
| [dry-monads](https://dry-rb.org) / [dry-initializer](https://dry-rb.org) | Result objects; declarative constructor params | We already depend on dry-validation. Our services return records with errors attached, which works — this is a stylistic migration to weigh, not a gap |
| [derailed_benchmarks](https://github.com/zombocom/derailed_benchmarks) | Memory and boot-time benchmarking | Nice-to-have; boot time is not a complaint yet |
| [rspec-instafail](https://github.com/grosser/rspec-instafail) / [fuubar](https://github.com/thekompanee/fuubar) | Failure output during the run; progress bar formatter | Trivial DX wins, more noticeable once the suite grows past its current ~10s |

---

## 3. Irrelevant / redundant / bad idea

| Gem | What it does | Why not |
|-----|--------------|---------|
| [database_consistency](https://github.com/djezzzl/database_consistency) | Audits schema vs. model validation mismatches | Redundant with `active_record_doctor`, already configured in `.active_record_doctor` and wired into `db:doctor`. Two tools, two ignore lists, same findings |
| [database_validations](https://github.com/toptal/database_validations) | Replaces uniqueness validators with DB-constraint rescues | Rescuing `PG::UniqueViolation` inside our explicit `ActiveRecord::Base.transaction` blocks (chronicles, memories controllers) aborts the whole transaction. The three duplicated reverse validators in `location.rb`, `weblink.rb`, `member.rb` should just be deleted instead |
| [discard](https://github.com/jhawthorn/discard) | Soft-deletion via a `discarded_at` column | Our `Archivable` concern already does this, plus retention periods, cascade archiving and a nightly cleanup job it does not have |
| [nanoid](https://github.com/radeno/nanoid.rb) | Short URL-safe unique IDs | We have YIDs (`code_timestamp_hex`) with Base64 url-safe encoding and prefix-based model lookup in `ApplicationRecordYidEnabled` |
| [devise](https://github.com/heartcombo/devise) | Full authentication framework | We deliberately built auth on `has_secure_password` + `Login` + email verification. Swapping is a rewrite of a working, tested subsystem |
| [sidekiq](https://github.com/sidekiq/sidekiq) / [sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron) / [good_job](https://github.com/bensheldon/good_job) / [schked](https://github.com/bibendi/schked) | Redis- or PG-backed job processing and scheduling | Solid Queue with recurring tasks is in place and `TODO_DATABASE.md` commits to it on Postgres. No Redis in the stack |
| [anycable-rails](https://anycable.io) | Go-based Action Cable replacement for high WS concurrency | Solid Cable is sufficient; this solves a scale problem we do not have |
| [stoplight](https://github.com/bolshakov/stoplight) / [redlock](https://github.com/leandromoreira/redlock-rb) | Circuit breaker; distributed Redis lock | Both want Redis. Single-host deployment, no distributed coordination needs |
| [standard](https://github.com/standardrb/standard) | Opinionated zero-config Ruby style | Directly conflicts with our tuned RuboCop setup (7 plugins, custom `.rubocop.yml`, 0 offenses) |
| [freezolite](https://github.com/evilmartians/freezolite) | Auto-enables frozen string literals without magic comments | RuboCop already enforces `# frozen_string_literal: true` project-wide and it is present everywhere |
| [fx](https://github.com/teoljungberg/fx) | Manages DB triggers and functions in schema.rb | We use scenic for views and generated columns (`thoughts.name`, `record_events.time`) instead of triggers. Nothing to manage |
| [pg_trunk](https://github.com/nepalez/pg_trunk) | Broad Postgres object management in migrations | Overlaps scenic + `fix-db-schema-conflicts`; would mean re-tooling schema management for no current gain |
| [postgresql_cursor](https://github.com/afair/postgresql_cursor) | Cursor-based iteration over huge result sets | Dataset sizes are nowhere near needing cursors; `find_in_batches` suffices |
| [anyway_config](https://github.com/palkan/anyway_config) | Layered typed configuration objects | Four `ENV[]` reads in the entire app, plus encrypted credentials. Nothing to organize |
| [site_prism](https://github.com/site-prism/site_prism) | Page Object DSL for Capybara | 15 system specs do not justify the indirection layer |
| [stackprof](https://github.com/tmm1/stackprof) | Sampling profiler | Superseded by vernier for our Ruby version — pick one, listed above |
| [silencer](https://github.com/stve/silencer) | Suppresses log lines for selected routes | A few lines of Rails config achieve the same; not worth a dependency |
| [active_record-associated_object](https://github.com/kaspth/active_record-associated_object) / [active_job-performs](https://github.com/kaspth/active_job-performs) | Attach POROs to AR models; generate job classes from methods | Cuts against the `app/services` convention that archspec actively enforces. Two job classes exist total |
| [ruby_llm](https://rubyllm.com/) / [ruby_llm-schema](https://github.com/danielfriis/ruby_llm-schema) | Unified LLM client; structured output schemas | No AI features in the app or on the roadmap |
| [vite_rails](https://github.com/ElMassimo/vite_ruby) / [bundlebun](https://github.com/yaroslav/bundlebun) | JS bundling via Vite; bundled Bun runtime | We are importmap + Propshaft with no build step, deliberately |
| [inertia_rails](https://inertia-rails.dev/) / [alba-inertia](https://github.com/skryukov/alba-inertia) / [typelizer](https://github.com/skryukov/typelizer) / [js-routes](https://github.com/railsware/js-routes) | SPA bridge, serializers and TS types for a JS frontend | No SPA, no TypeScript. Hotwire + Slim server-rendered views |
| [alba](https://github.com/okuramasafumi/alba) / [panko_serializer](https://github.com/panko-serializer/panko_serializer) / [skooma](https://github.com/SchemaLab/skooma) | Fast JSON serialization; OpenAPI response validation | No public JSON API surface today |
| [graphql](https://github.com/rmosolgo/graphql-ruby) + [connections](https://github.com/Shopify/graphql-connections) / [fragment_cache](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache) / [persisted_queries](https://github.com/DmitryTsepelev/graphql-ruby-persisted_queries) / [action_policy-graphql](https://github.com/palkan/action_policy-graphql) / [schema_comparator](https://github.com/xuorig/graphql-schema_comparator) | GraphQL server and its ecosystem | No GraphQL, and adding it would duplicate the existing REST-ish controller + policy layer |
| [yabeda-sidekiq](https://github.com/yabeda-rb/yabeda-sidekiq) | Sidekiq metrics for Yabeda | No Sidekiq |
| [dry-effects](https://dry-rb.org) | Algebraic effects for implicit context passing | `Current` attributes already carry request context; this would obscure it |
