# TODO: Move the Solid Stack to PostgreSQL

Branch: `database`

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

- [ ] `yournaling_queue_db_name` (default `"#{yournaling_db_name}_queue"`).
- [ ] `yournaling_cache_db_name` (default `"#{yournaling_db_name}_cache"`).
- [ ] `yournaling_cable_db_name` (default `"#{yournaling_db_name}_cable"`).
- [ ] Helper URL methods mirroring `yournaling_db_url`:
      `yournaling_queue_db_url`, `yournaling_cache_db_url`,
      `yournaling_cable_db_url` (same host/port/credentials as primary, different
      `dbname`).
- [ ] Review the `pool:` size note in `database.yml` — with 4 Postgres databases
      each process now opens up to 4 pools; keep the formula but sanity-check the
      total against local Postgres `max_connections` (default 100) especially
      under parallel specs (`workers × 4 × pool`).
- [ ] Document the new keys in `config/app_conf.local.rb` (gitignored) as
      examples for overriding host/credentials locally.

---

## Phase 2 — `db/` layout & schema files

Goal: `primary` and `queue` are migration-managed and schema-dumped; `cache` and
`cable` load from a committed schema and are not migrated.

- [ ] Keep `db/migrate` (primary) and `db/migrate_queue` (queue).
- [ ] Regenerate the Solid schema files for **PostgreSQL** (they are currently
      SQLite-shaped):
  - [ ] `db/queue_schema.rb` — take the canonical Postgres schema from the
        installed `solid_queue` gem (re-run its installer/generator against
        Postgres) rather than hand-editing `force: :cascade` etc.
  - [ ] `db/cache_schema.rb` — same, from `solid_cache`.
  - [ ] `db/cable_schema.rb` — same, from `solid_cable`.
  - [ ] Replace `db/migrate_queue/*` with the gem's current Postgres migration
        (or re-dump the create-tables migration for Postgres).
  - [ ] `db/migrate_cache/*` and `db/migrate_cable/*` can be deleted once those
        databases are created via `db:schema:load` from the new schema files
        (they will be `database_tasks: false`).
- [ ] `bin/rails db:prepare` must create and load all 4 databases from a clean
      state.
- [ ] Remove the now-unused `storage/*.sqlite3` files from the working tree and
      confirm `storage/` handling in `.gitignore` still makes sense.

---

## Phase 3 — `config/database.yml` rewrite

Replace the SQLite anchors with Postgres. Target shape:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= AppConf.rails_max_threads.to_i + 3 * AppConf.job_concurrency.to_i + 5 %>
  timeout: <%= AppConf.yournaling_db_timeout_seconds.to_i * 1000 %>
  connect_timeout: <%= AppConf.yournaling_db_timeout_seconds.to_i %>
  reconnect: true
  variables:
    statement_timeout: <%= AppConf.yournaling_db_timeout_seconds.to_i * 1000 %>

development:
  primary:
    <<: *default
    url: <%= "#{AppConf.yournaling_db_url}_development" %>
    migrations_paths: db/migrate
  queue:
    <<: *default
    url: <%= "#{AppConf.yournaling_queue_db_url}_development" %>
    migrations_paths: db/migrate_queue
  cache:
    <<: *default
    url: <%= "#{AppConf.yournaling_cache_db_url}_development" %>
    schema_dump: cache_schema.rb
    database_tasks: false
  cable:
    <<: *default
    url: <%= "#{AppConf.yournaling_cable_db_url}_development" %>
    schema_dump: cable_schema.rb
    database_tasks: false

test:
  primary:
    <<: *default
    url: <%= "#{AppConf.yournaling_db_url}_test#{ENV['TEST_ENV_NUMBER']}" %>
    migrations_paths: db/migrate
  queue:
    <<: *default
    url: <%= "#{AppConf.yournaling_queue_db_url}_test#{ENV['TEST_ENV_NUMBER']}" %>
    migrations_paths: db/migrate_queue
  cache:
    <<: *default
    url: <%= "#{AppConf.yournaling_cache_db_url}_test#{ENV['TEST_ENV_NUMBER']}" %>
    schema_dump: cache_schema.rb
    database_tasks: false
  cable:
    <<: *default
    url: <%= "#{AppConf.yournaling_cable_db_url}_test#{ENV['TEST_ENV_NUMBER']}" %>
    schema_dump: cable_schema.rb
    database_tasks: false

production:
  # see the "Production Rollout" section — kept minimal here on purpose
  primary:
    <<: *default
    url: <%= AppConf.yournaling_db_url %>
    migrations_paths: db/migrate
  queue:
    <<: *default
    url: <%= AppConf.yournaling_queue_db_url %>
    migrations_paths: db/migrate_queue
  cache:
    <<: *default
    url: <%= AppConf.yournaling_cache_db_url %>
    schema_dump: cache_schema.rb
    database_tasks: false
  cable:
    <<: *default
    url: <%= AppConf.yournaling_cable_db_url %>
    schema_dump: cable_schema.rb
    database_tasks: false
```

- [ ] Keep the `TEST_ENV_NUMBER` suffix on **every** database name so parallel
      specs stay isolated — each parallel worker gets its own set of 4 Postgres
      databases.
- [ ] Update the header NOTE comment block to describe "4 PostgreSQL databases".
- [ ] Drop the `sqlite3:` / `*_config` anchors entirely.

---

## Phase 4 — Rails wiring

- [ ] `config/application.rb` — `config.solid_queue.connects_to = { database: {
      writing: :queue } }` stays. (No `reading:` split until a replica exists.)
- [ ] `app/models/application_record.rb` — if it does not already, keep it on the
      default `primary` connection; no role switching in dev/test.
- [ ] `config/cable.yml` — `solid_cable` already `connects_to … writing: cable`;
      no change needed beyond the database now being Postgres. Sanity-check
      `polling_interval: 0.1` against local Postgres (fine for dev).
- [ ] `config/cache.yml` — `database: cache` stays. Verify `solid_cache`
      trimming / `max_size` behaves on Postgres.
- [ ] `config/queue.yml` — no logical change.
- [ ] `config/environments/development.rb` / `test.rb` — remove any assumptions
      about SQLite storage paths; confirm `config.cache_store` /
      `active_job.queue_adapter` still resolve.
- [ ] `mission_control-jobs` dashboard — confirm it targets the `queue`
      connection.
- [ ] `config/blazer.yml` — still uses the primary connection; unchanged.
- [ ] `Gemfile` — remove `gem "sqlite3"` and its comment once dev/test run green
      on Postgres. Run `bundle install` and commit `Gemfile.lock`.

---

## Phase 5 — Migrations & schema management (primary + queue)

- [ ] `bin/rails db:prepare` creates all 4 DBs; `db:migrate` only touches
      `primary` + `queue` (`cache`/`cable` are `database_tasks: false`).
- [ ] After migrating, `db/schema.rb` and `db/queue_schema.rb` are the dumped
      schemas and are committed.
- [ ] `db/cache_schema.rb` / `db/cable_schema.rb` are committed but only updated
      when the gems change.

---

## Phase 6 — Local & CI setup

- [ ] Update `README` / setup docs: developers need a running PostgreSQL and run
      `bin/rails db:prepare` (or `bin/setup`) to get all 4 databases.
- [ ] `bin/setup` — ensure it creates/loads the new databases and no longer
      references SQLite files.
- [ ] CI config — ensure the Postgres service is available (it already is for
      `primary`) and `db:prepare` provisions queue/cache/cable. Confirm parallel
      test setup (`rails db:test:prepare` / `parallelize`) creates the per-worker
      databases.
- [ ] `rake ci` / quality gates — run the full suite on Postgres-backed Solid
      Stack and fix fallout (SQLite-specific SQL, `pragma`, datetime precision,
      `rowid` assumptions, ordering that relied on SQLite insertion order).
- [ ] Grep the codebase/specs for `sqlite`, `.sqlite3`, `storage/` DB paths and
      clean up.

---

## Phase 7 — Verification

- [ ] `bin/dev` boots; enqueue a job, worker picks it up from Postgres `queue`.
- [ ] Recurring task (`config/recurring.yml`) registers and runs.
- [ ] Action Cable broadcast reaches the browser (Postgres `cable`).
- [ ] `Rails.cache.write/read` round-trips via Postgres `cache`.
- [ ] Mission Control jobs dashboard renders.
- [ ] Full `rake ci` green, including parallel specs.
- [ ] `db:prepare` from a dropped state reproduces everything.

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
