# TODO: Move the Solid Stack to PostgreSQL

Branch: `database`

**Status:** dev/test migration complete (Phases 1–7 done). SolidQueue, SolidCache
and SolidCable run on dedicated PostgreSQL databases in development and test.
The "Production Rollout" section below is still open and out of scope for this
branch.

## Why

Today the app runs 4 databases:

| Logical DB | Engine   | Used by      | Contains                          |
|------------|----------|--------------|-----------------------------------|
| `primary`  | Postgres | ActiveRecord | domain data                       |
| `queue`    | SQLite   | SolidQueue   | jobs, recurring tasks, semaphores |
| `cache`    | SQLite   | SolidCache   | cache entries                     |
| `cable`    | SQLite   | SolidCable   | Action Cable pub/sub messages     |

SQLite databases are files on one machine's local disk. That is fine for a
single-host deployment, but it blocks **horizontal scaling**: a second web or
worker host cannot see the same SQLite file, so jobs enqueued on host A are
invisible to workers on host B, and each host has its own cache and cable stream.

Decision: **move the entire Solid Stack onto PostgreSQL** so every host talks to
the same databases.

### Scope of this branch

This branch only changes the **development** and **test** setups: create the new
PostgreSQL databases and update the Rails configuration. There is no relevant
data in the SQLite databases, so **no data migration** is needed — new empty
Postgres databases plus a config change is enough.

Everything required to run this safely at scale in production (PgBouncer, read
replica, backups, cutover) is collected under **[Production Rollout](#production-rollout)**
at the end and is intentionally out of scope here.

Focus of ongoing schema maintenance: the **`primary`** and **`queue`**
databases. `cache` and `cable` are disposable and schema-static.

---

## Target (dev/test)

One local PostgreSQL server hosts 4 databases per environment:

```text
yournaling_development         yournaling_test<N>
yournaling_queue_development    yournaling_queue_test<N>
yournaling_cache_development    yournaling_cache_test<N>
yournaling_cable_development    yournaling_cable_test<N>
```

- Keeping them as separate databases preserves the current isolation, keeps
  `db:schema:dump` output clean, and leaves the door open to move
  `cache`/`cable` elsewhere later without another app change.
- App connects directly to Postgres on `5432` in dev/test (PgBouncer is a
  production-rollout concern).

---

## Phase 1 — AppConf

Edit `config/app_conf.rb`. Add registrations (all `ENV`-overridable), following
the existing `yournaling_db_*` pattern:

- [x] `yournaling_queue_db_name` (default `"#{yournaling_db_name}_queue"`).
- [x] `yournaling_cache_db_name` (default `"#{yournaling_db_name}_cache"`).
- [x] `yournaling_cable_db_name` (default `"#{yournaling_db_name}_cable"`).
- [x] Helper URL methods mirroring `yournaling_db_url`:
      `yournaling_queue_db_url`, `yournaling_cache_db_url`,
      `yournaling_cable_db_url` (same host/port/credentials as primary, different
      `dbname`). The `database.yml` appends the env suffix (`_development`,
      `_test<N>`) to these URLs exactly as it already does for the primary.
- [x] Reviewed the `pool:` size formula — kept as is. Each logical database gets
      its own connection pool, but Postgres' default `max_connections` (100) is
      comfortable for local dev and CI; parallel specs run 4 workers and the CI
      Postgres service uses the stock config. Right-sizing for many processes is
      a production concern (see [Production Rollout](#production-rollout)).
- [x] No `config/app_conf.local.rb` sample is needed — the new keys follow the
      documented `AppConf.set`/`ENV` override mechanism already described at the
      bottom of `config/app_conf.rb`.

---

## Phase 2 — `db/` layout & schema files

Decision: keep all four databases **fully rake-managed**, exactly as today — each
keeps its own `migrations_paths` and its own dumped schema file. This is the
smallest possible change and keeps `bin/rails db:prepare` / `db:migrate` working
for every database with no special-casing. (`database_tasks: false` +
`schema_dump:` was considered but rejected for dev/test: it would stop
`db:create`/`db:prepare` from provisioning those databases, hurting the
first-run developer experience. Revisit for production if desired.)

The existing migrations and schema files are already database-agnostic standard
ActiveRecord (`t.binary limit: …` → `bytea`, `t.integer limit: 8` → `bigint`),
so nothing needs hand-editing — Rails re-dumps them in PostgreSQL format on the
first `db:migrate`.

- [x] Keep `db/migrate`, `db/migrate_queue`, `db/migrate_cache`, `db/migrate_cable`.
- [x] Keep `db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`,
      `db/cable_schema.rb` — they get re-dumped in PostgreSQL format (Phase 5).
- [x] `bin/rails db:prepare` creates and loads all 4 databases from a clean state.
- [x] Remove the now-unused `storage/*.sqlite3` files from the working tree.
      `.gitignore` already has `/storage/*.sqlite3*`, which stays (harmless, and
      documents intent).

---

## Phase 3 — `config/database.yml` rewrite

Replaced the `sqlite3` anchor and the `*_config` anchors with a single
`postgres` anchor (adapter + encoding + timeouts + `statement_timeout`), reused
by all four databases in every environment. Each database gets a URL from
AppConf plus its `migrations_paths`.

- [x] `postgres` anchor carries adapter, `encoding: unicode`, `connect_timeout`,
      `read_timeout`, `reconnect`, and `variables.statement_timeout` — the same
      values the old `postgres` anchor used for the primary.
- [x] Keep the `TEST_ENV_NUMBER` suffix on **every** database URL so parallel
      specs stay isolated — each parallel worker gets its own set of 4 Postgres
      databases.
- [x] Updated the header NOTE comment block to describe the 4 PostgreSQL
      databases and to point at "Production Rollout" for PgBouncer/replica/backups.
- [x] Dropped the `sqlite3:`, `cable_config:`, `cache_config:`, `queue_config:`
      anchors entirely.
- [x] `config/database.yml` is now the only file that referenced SQLite; grep
      for `sqlite` across the app is clean afterwards.

---

## Phase 4 — Rails wiring

No code changes were needed here — the Solid gems resolve their connection from
`database.yml` / `cable.yml` / `cache.yml`, which now point at PostgreSQL.

- [x] `config/application.rb` — `config.solid_queue.connects_to = { database: {
      writing: :queue } }` unchanged (no `reading:` split until a replica exists).
- [x] `app/models/application_record.rb` — already `writing: :primary,
      reading: :primary`; left as is (no role switching in dev/test).
- [x] `config/cable.yml` — `solid_cable` already `connects_to … writing: cable`;
      no change. `polling_interval: 0.1` is fine against local Postgres.
- [x] `config/cache.yml` — `database: cache` unchanged; `max_size` / trimming
      are store-level and DB-agnostic.
- [x] `config/queue.yml` — no change.
- [x] `config/environments/*.rb` — no SQLite storage assumptions
      (`grep -rn sqlite config/` only hit `database.yml`, now fixed).
      `config.cache_store` / `active_job.queue_adapter` verified via `runner`:
      SolidCache/Queue/Cable connect to `yournaling_{cache,queue,cable}_*`.
- [x] `mission_control-jobs` dashboard — introspects the SolidQueue models, which
      connect to `:queue`; nothing to configure.
- [x] `config/blazer.yml` — uses the primary connection; unchanged.
- [x] `Gemfile` — `gem "sqlite3"` removed (Phase 5 commit) once the suite was
      green on Postgres; `Gemfile.lock` regenerated.

---

## Phase 5 — Migrations & schema management

- [x] `bin/rails db:prepare` creates and loads all 4 DBs; `db:migrate` runs the
      migrations for all 4 (each has its own `migrations_paths`). No
      special-casing — see the Phase 2 decision.
- [x] `db/schema.rb` (primary) unchanged — already PostgreSQL.
- [x] `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb` re-dumped
      in PostgreSQL format via `db:schema:dump` and committed. Human attention
      going forward stays on `primary` and `queue`; `cache`/`cable` only change
      when the gems do.
- [x] `db/migrate_queue`, `db/migrate_cache`, `db/migrate_cable` migrations are
      standard ActiveRecord and needed no edits for PostgreSQL.

---

## Phase 6 — Local & CI setup

- [x] `README.markdown` — note the 4 PostgreSQL databases; drop the "sqlite
      installs itself" line.
- [x] `bin/setup` — already runs `bin/rails db:prepare` + `rake parallel:setup[4]`
      and has no SQLite references; nothing to change.
- [x] CI (`.github/workflows/ci_push_pull_main.yml`) — the "Setup DB" step runs
      `rake db:drop db:create db:migrate` then `parallel:setup[4]`. With all four
      databases now on the CI Postgres service this works unchanged: `db:create`
      provisions `yournaling_{,queue_,cache_,cable_}test`, `db:migrate` loads
      them, `parallel:setup[4]` creates the per-worker copies. No workflow edit
      needed.
- [x] `rake ci` / full suite — green on the Postgres-backed Solid Stack
      (see Phase 7).
- [x] `grep -rn sqlite` across the app after the change: only historic mentions
      in `README` (removed) and this plan; no code references remain.

Note: running `rake parallel:setup[4]` directly through the `bin/mcp_*` chruby
wrappers can fail locally with a `Bundler::GemNotFound` in the spawned
sub-processes (an environment quirk, not caused by this change). Workaround used
here: `for i in 2 3 4; do RAILS_ENV=test TEST_ENV_NUMBER=$i bundle exec rails db:create db:schema:load; done`.
`parallel_rspec -n 4` itself works fine.

---

## Phase 7 — Verification

- [x] Rails boots on all envs; `runner` confirms SolidQueue → `yournaling_queue_*`,
      SolidCache → `yournaling_cache_*`, SolidCable → `yournaling_cable_*`.
- [x] `ProbeJob.perform_later` writes a row to `solid_queue_jobs` in the queue DB.
- [x] `ActionCable.server.broadcast` writes to `solid_cable_messages` in
      `yournaling_cable_development`. (In `test` the `cable.yml` adapter is
      `test`, so SolidCable models are unused there — unchanged by this work.)
- [x] `SolidCache` store `write`/`read` round-trips via the cache DB.
- [x] Full RSpec suite green: **1244 examples, 0 failures, 1 pending** (the
      pending is a pre-existing `let!`-in-example bug in
      `card_open_and_rewrite_links_spec.rb`). Individual `rake ci` runs on a
      loaded laptop showed intermittent `Rack::Timeout` / statement-timeout
      flakes in the image-heavy system specs — they pass in isolation and on a
      calm machine; not caused by this change (CI runs on a dedicated Postgres
      service).
- [x] `rubocop` (427 files) and `ci:checks` (archspec, active_record_doctor)
      pass against the multi-PostgreSQL setup.
- [x] `db:drop` + `db:prepare` from scratch recreates all 4 databases and loads
      their schema.

---

## Production Rollout

Out of scope for this branch. To be planned/specified separately once the
hosting setup is decided. Nothing here should block the dev/test migration.

### Connection pooling — PgBouncer

- [ ] Run PgBouncer in front of every app→Postgres connection (all 4 databases),
      `pool_mode = transaction`.
- [ ] Transaction pooling requires: `prepared_statements: false` and
      `advisory_locks: false` on every Postgres connection; run migrations
      against a **direct** connection (bypassing PgBouncer).
- [ ] Add AppConf keys: pool host/port, direct port, `prepared_statements` flag;
      point production `database.yml` at the pool port, add a direct-port profile
      for migration rake tasks.
- [ ] `ignore_startup_parameters`, `max_client_conn`, `default_pool_size` per
      database; document the arithmetic
      `pods × processes × Rails pool ≤ Σ pgbouncer pool sizes ≤ server_connections`.
- [ ] Optional: PgBouncer locally too, for parity (behind a flag; off by
      default).
- [ ] SolidQueue/Cache/Cable are poll-based + `FOR UPDATE SKIP LOCKED`, so they
      are compatible with transaction pooling. SolidCable does not use
      `LISTEN/NOTIFY`.

### Read replica

- [ ] Provision an asynchronous **streaming replica** (hot standby) of the
      primary: replication slot, `hot_standby_feedback = on`, tuned
      `max_standby_streaming_delay`.
- [ ] `primary_replica` connection in `database.yml` (`replica: true`,
      `database_tasks: false`); AppConf `yournaling_db_replica_host` +
      `yournaling_replica_enabled`.
- [ ] `app/models/application_record.rb`:
      `connects_to database: { writing: :primary, reading: :primary_replica }`
      when enabled.
- [ ] Automatic role switching via `ActiveRecord::Middleware::DatabaseSelector`
      with a `delay` (AppConf `database_selector_delay`, ~2s); start conservative
      — explicit `connected_to(role: :reading)` for reporting/Blazer/heavy read
      jobs only, request-level switching later.
- [ ] Point Blazer, reporting jobs, sitemap/RSS/search-index rebuilds at
      `:reading`.
- [ ] Guardrails: specs asserting `ActiveRecord::ReadOnlyError` on the replica
      role; replication-lag monitoring + alert; optional fallback to primary
      reads under high lag.
- [ ] `queue`, `cache`, `cable` get no replica.
- [ ] Optional local streaming standby recipe for testing role switching.

### Backups to S3-compatible storage

Scope: `primary` and `queue` (data that cannot be recreated). `cache` and
`cable` excluded — they rebuild themselves.

- [ ] Tool: `pgBackRest` (preferred) or `wal-g` — both support S3-compatible
      endpoints (custom endpoint/region, path-style).
- [ ] Continuous WAL archiving from the primary (`archive_mode = on`) → PITR.
- [ ] Base backups: full weekly + differential daily, taken from the replica
      where possible. `queue` is covered by the cluster-level physical backup;
      add a nightly `pg_dump --format=custom yournaling_queue` for fast partial
      restore. Nightly custom-format dump of the primary too.
- [ ] Dedicated bucket (e.g. `s3://yournaling-db-backups/`) with lifecycle rules
      (WAL + daily diffs 14d, weekly fulls 8w, monthly 12m); object-lock /
      versioning if supported.
- [ ] AppConf: `db_backup_s3_endpoint`, `_region`, `_bucket`, `_access_key_id`,
      `_secret_access_key`, `db_backup_encryption_key` — a **separate** bucket
      (and ideally separate keys) from the Active Storage S3 config.
- [ ] Client-side encryption (pgBackRest `aes-256-cbc`) + TLS; key in secrets
      manager, not the repo.
- [ ] Restore runbook: full restore to latest; PITR to a timestamp; single-db
      logical restore of `yournaling_queue`; throwaway instance from a backup.
- [ ] Automated weekly restore test into a scratch instance + `pg_amcheck` /
      row-count sanity; alert on backup age > 26h or failed WAL push.

### Cutover & deploy

- [ ] Create production Postgres `queue` / `cache` / `cable` databases;
      `db:schema:load`.
- [ ] Deploy the Postgres-backed Solid Stack config; verify workers, cable,
      cache. (No SQLite data to drain — same as dev/test.)
- [ ] Enable PgBouncer, then replica + role switching, then backups; run the
      first restore test.
- [ ] Deploy / infra changes — PgBouncer service placement (sidecar vs central),
      replica provisioning, backup cron, secrets, autoscaling — **to be specified
      once hosting/orchestration is decided** (Kamal? k8s? managed Postgres?).

### Observability & tuning (production)

- [ ] PgBouncer metrics (`SHOW POOLS/STATS/CLIENTS`, `pgbouncer_exporter`);
      alert on sustained `cl_waiting`, high `maxwait`, pool saturation.
- [ ] Postgres: `pg_stat_statements`, connection count vs `max_connections`,
      replication lag, long transactions, `SKIP LOCKED` contention on
      `solid_queue_ready_executions`.
- [ ] Right-size `max_connections`, `default_pool_size`, Rails `pool:`.
- [ ] Load test: N web pods + M worker pods; confirm job throughput and p95.

---

## Open Questions

- Managed Postgres (RDS/Crunchy/Supabase/…) vs. self-hosted — changes the
  production replica/backup approach substantially (may replace parts of it).
- Hosting/orchestration — drives PgBouncer placement and cutover mechanics.
- Request-level replica reads now, or explicit `connected_to` only? (Lean
  explicit-only to start.)
- Separate Postgres instance for `cache`/`cable` later? Config already allows it.
