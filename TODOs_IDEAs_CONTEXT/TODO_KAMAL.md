# TODO — Kamal 2 Deployment (staging first)

Status: **§1–4 implemented** (not yet deployed — no server/secrets) · Branch: `kamal2` · Updated: 2026-09-03
Runbook: [`README_BUILD_AND_DEPLOY.markdown`](../README_BUILD_AND_DEPLOY.markdown)

References:
- Website: https://kamal-deploy.org/
- Docs (v2.x): https://kamal-deploy.org/docs/installation/
- Destinations: https://kamal-deploy.org/docs/configuration/environments/
- Source: https://github.com/basecamp/kamal
- GHA pattern the old branch pointed at: https://jetthoughts.com/blog/automate-your-deployments-with-kamal-2-github-actions-devops-development/

---

## 0. What changed since the first draft (2026-09-01)

Two things on `main` reshape this plan:

1. **The Solid Stack is 100% PostgreSQL now** (`#83 Migrate Solid Stack from SQLite to PostgreSQL`).
   SolidQueue / SolidCache / SolidCable no longer use SQLite files under `storage/`. The app
   runs **four PostgreSQL databases** — `primary`, `queue`, `cache`, `cable` — each with its
   own schema file and migration path (`db/migrate{,_queue,_cache,_cable}`). See
   [config/database.yml](../config/database.yml). Consequences:
   - No `/data/storage` volume is needed for the Solid* databases any more.
   - The old "web and job containers must share the same host + volume" constraint is **gone**.
     Web and jobs only need to reach the same Postgres.
   - `bin/rails db:prepare` now creates/migrates all four databases in one call.
   - `AppConf` gained `yournaling_cable_db_url`, `yournaling_cache_db_url`,
     `yournaling_queue_db_url` (all `required: production_env`).

2. **A `staging` environment exists** (`#88 Add staging environment configuration`).
   - `config/environments/staging.rb` loads `production.rb` and only widens host auth.
   - `AppConf.production_env` returns **true for `staging` as well as `production`**, so every
     production-grade setting (required ENV, S3 storage, STDOUT logging, `force_ssl`, no pidfile)
     already applies to staging.
   - `config/database.yml` has a `staging:` block that reuses the `production:` block via a YAML
     anchor — same shape, the URLs just point at one server.
   - `config/{cable,cache,queue}.yml` have `staging:` sections.
   - CI (`.github/workflows/ci_push_pull_main.yml`) already sets
     `BUNDLE_WITHOUT: development:staging:production` — it expects deploy gems to live in a
     `:staging` / `:production` (or shared `:deploy`) group, not in `:development, :test`.

**This plan now targets a staging deployment.** Everything that only matters for production
(horizontal scaling, multiple app servers, dedicated/managed database servers, read replicas,
Postgres tuning, at-scale backups) is collected in **§5 Production rollout** and deferred.

---

## 1. What exists today

### On `main`
- `gem "kamal"` is in the `Gemfile`, still inside `group :development, :test` (line ~66). Nothing
  else Kamal-related is committed: no `Dockerfile`, no `config/deploy.yml`, no `.kamal/`, no
  `.dockerignore`, no deploy workflow.
- `bin/thrust` and `bin/jobs` binstubs exist. **`bin/thrust` is dead** — the `thruster` gem is
  not in the `Gemfile`/`Gemfile.lock` yet. `bin/jobs` runs the SolidQueue supervisor.
- Stack: Ruby **4.0.6** (`.ruby-version`), Rails `~> 8.1.3`, Puma `~> 8.0`, Propshaft with
  dartsass and importmap, Slim, ViewComponent.
- DB: **PostgreSQL only** (`pg ~> 1.1`), four databases (see §0). `pg_search` + `scenic` in use.
- Image processing: `image_processing ~> 2.0` + `ruby-vips` → needs system **libvips** (CI also
  installs `libpoppler-glib8` for PDF thumbnailing).
- ActiveStorage → **Amazon S3** (`amazon_s3` service, region `eu-central-1`), keyed on
  `AppConf.amazon_s3_*`. **`aws-sdk-s3` is not in the `Gemfile`** — the `S3` service will not
  resolve until it is added.
- Geocoding → Geoapify (`AppConf.geoapify_api_*`).
- Mail: `config/environments/production.rb` sets `delivery_method = :smtp` with **no
  `smtp_settings`** — sending mail will raise until SMTP ENV/config is added (staging inherits
  this from `production.rb`).
- Health check route: `GET /up` → `health#show` (Kamal's default readiness probe).
- `production.rb` sets `config.assume_ssl = true` and `config.force_ssl = true`. The `/up`
  exclusion lines for `ssl_options` and `host_authorization` are **commented out**.
  `staging.rb` already adds `host_authorization = { exclude: /up }` and appends
  `AppConf.yournaling_host` to `config.hosts`.
- Config is centralised in `config/app_conf.rb` (`AppConf`), reading ENV. Keys relevant to a
  deploy, **all `required: production_env`** (i.e. mandatory for `staging`):
  `yournaling_host`, `yournaling_db_name`, `yournaling_db_timeout_seconds`,
  `yournaling_db_url`, `yournaling_cable_db_url`, `yournaling_cache_db_url`,
  `yournaling_queue_db_url`, `rails_secret_key_base`,
  `amazon_s3_access_key_id` / `amazon_s3_secret_access_key` / `amazon_s3_bucket_name`,
  `geoapify_api_key` / `geoapify_api_url`.
  Non-secret tunables with defaults: `web_concurrency` (1), `job_concurrency` (1),
  `solid_queue_in_puma` (false), `rails_max_threads` (6), `yournaling_port` (3008).
- CI: `.github/workflows/ci_push_pull_main.yml` (tests + lint, runs on PR + push to `main`).

> ⚠️ **`required: production_env` means `ENV.fetch` with no fallback.** For a staging deploy the
> four `YOURNALING_*_DB_URL` values must each be provided explicitly as ENV — the composed-from-
> parts defaults are *not* used when `required: true`. Either supply all four URLs in
> `deploy.yml`/secrets, or (small app change, see §4) relax those four to
> `required: false` so they compose from `YOURNALING_DB_{HOST,PORT,NAME,USERNAME,PASSWORD}`.

### Stale prior art (do not cherry-pick — rewrite)
- **`origin/kamal` branch** (forked ~54 commits back): a full but unfinished, partly AI-generated
  Kamal 2 setup — `Dockerfile` (Ruby 3.3.6, broken `YOURNALING_DB_URL` build-ARG block),
  `.dockerignore` (standard, reusable), `bin/docker-entrypoint` (jemalloc + `db:prepare`,
  reusable idea), `bin/kamal`, `bin/provision` (Ubuntu host bootstrap, useful reference),
  `config/deploy.yml` (**duplicate keys**, hardcoded to one Hetzner IP, `postgres:17` accessory
  with a single DB, SQLite-era `/data/storage` volume), `.kamal/secrets` (1Password adapter,
  **`NAME:` vs `NAME=` shell-syntax bug**, `POSTGRES_*` / `RAILS_MASTER_KEY` naming that does
  **not** match `AppConf`), `.github/workflows/deploy.yml` (name + two TODO comments only),
  `config/postgres_production.conf` (844-line tuning dump). Treat every "done" claim as
  unverified.
- **`origin/dockerize` branch**: a plain Rails-8-generated `Dockerfile` (Ruby 3.3.1, no
  Thruster). Superseded.
- The old **`Kamal_Deployment.markdown`** status doc (was untracked on `yui-design`, now gone)
  claimed: Hetzner server IP **188.245.99.209**, firewall 22/80/443, DNS **yournaling.com** →
  that IP, SSH configured, `.kamal/secrets` wired to 1Password under `yournaling.com/Production`,
  Docker installed locally. **All unverified — re-check before any real deploy.** For staging we
  most likely want a *separate, small* box and a `staging.yournaling.com` (or similar) hostname.

---

## 2. Scope & decisions

**In scope now — a staging deployment:**
1. **DB topology (staging):** Postgres 17 as a **Kamal accessory on the same single host**,
   bind-mounted volume, off-server backup. All four logical databases live in that one Postgres
   instance. (Managed/external Postgres is a valid drop-in — point the four `YOURNALING_*_DB_URL`
   at it and remove the accessory — but not the default for staging.)
2. **One box for everything.** Web + jobs + Postgres on a single server. Run the SolidQueue
   supervisor **inside Puma** (`SOLID_QUEUE_IN_PUMA=true`) → a single app container, no separate
   `job` role. (`bin/jobs` as a second role stays documented as the production shape.)
3. **GitHub Actions workflow:** build **+ push + deploy to staging**, **manually triggered**
   (`workflow_dispatch`). The deploy job is **active** (manual trigger = intentional), but the
   whole thing is a no-op until the staging server + secrets exist.
   *Near-term evolution (documented, not enabled yet):* add `push: branches: [main]` so a merge
   to `main` auto-deploys staging.
4. **Thruster:** yes — add the `thruster` gem, container `CMD ["./bin/thrust", "./bin/rails",
   "server"]`, Kamal proxy → Thruster on port 80 in-container.
5. **Secrets:** 1Password CLI adapter for local `kamal` runs (vault item `yournaling.com/Staging`);
   GitHub Actions uses its own Actions secrets (+ optional 1Password service-account token).
6. **Local image build** must work for smoke testing (native arch) and parity testing
   (`linux/amd64`).
7. **ENV naming:** standardise on the **`AppConf` names** (`YOURNALING_DB_*`,
   `RAILS_SECRET_KEY_BASE`, `AMAZON_S3_*`, `GEOAPIFY_API_*`) everywhere — deploy.yml, secrets,
   1Password item — so no app code changes are needed for naming.

**Deferred to §5 Production rollout:** horizontal scaling, multiple app servers, dedicated
database server(s) / managed Postgres, read replicas, separate `job` role/containers,
`WEB_CONCURRENCY > 1`, `config/deploy.production.yml` destination, Postgres tuning conf,
at-scale / PITR backups, blue-green specifics, `db/seeds.rb` production seeding.

---

## 3. Target design — staging

### Container / image (`Dockerfile`)
- Registry: **GHCR** — `ghcr.io/mediafinger/yournaling` (+ build cache
  `ghcr.io/mediafinger/yournaling/build-cache`). Confirm `mediafinger` is the right owner/namespace.
- Base: `ruby:4.0.6-slim` (keep `ARG RUBY_VERSION` in sync with `.ruby-version`).
- Build platform: **linux/amd64** (Hetzner is x86-64). On Apple Silicon, Kamal's
  `builder.arch: amd64` cross-builds via buildx; first local build under emulation is slow →
  rely on the registry build cache and/or build in GHA.
- Runtime packages: `curl libjemalloc2 libvips postgresql-client` (+ `libpoppler-glib8` to match
  CI's PDF thumbnailing — confirm it's actually exercised in the deployed app).
- Build packages (throwaway stage): `build-essential git libpq-dev pkg-config`.
- Non-root `rails` user (uid/gid 1000); `chown` `db log storage tmp`.
- `bin/rails assets:precompile` at build with `SECRET_KEY_BASE_DUMMY=1`. **Verify precompile
  also runs the dartsass build** (`app/assets/builds/*.css`) and writes the Propshaft
  `.manifest.json`.
- `ENTRYPOINT ["/rails/bin/docker-entrypoint"]` — jemalloc preload; run `./bin/rails db:prepare`
  only when the command is the server (creates + migrates all four PG databases; the accessory's
  superuser has `CREATEDB`).
- `CMD ["./bin/thrust", "./bin/rails", "server"]`, `EXPOSE 80`.
- **Do not** bake DB URLs / secrets into the image. No `RAILS_MASTER_KEY` needed at build
  (dummy secret key base covers precompile).
- `.dockerignore`: start from the Rails 8 generated list (the `origin/kamal` one is fine).

### Gemfile
- Move `gem "kamal"` out of `:development, :test`. Add a group CI already expects:
  ```ruby
  group :deploy do              # or:  group :staging, :production do
    gem "kamal",    require: false
    gem "thruster", require: false
  end
  ```
  CI's `BUNDLE_WITHOUT: development:staging:production` — extend to also skip `deploy` if that
  name is used. `bundle install`, commit `Gemfile.lock` (Ruby 4.0.6 gem set).
- Add `gem "aws-sdk-s3", require: false` (top-level or `:deploy`) so the `S3` ActiveStorage
  service resolves in staging/production. **This is a hard blocker for a working deploy.**
- `bundle binstubs kamal thruster` → refresh `bin/kamal`, `bin/thrust`.

### `config/deploy.yml` + destinations (clean write — not a cherry-pick)
Use Kamal **destinations** from day one so production slots in later without a rewrite:
- **`config/deploy.yml`** — shared base:
  - `service: yournaling`, `image: mediafinger/yournaling`.
  - `registry: { server: ghcr.io, username: [KAMAL_REGISTRY_USERNAME], password: [KAMAL_REGISTRY_PASSWORD] }`.
  - `builder: { arch: amd64, args: { RUBY_VERSION: 4.0.6 }, cache: { type: registry, image: ghcr.io/mediafinger/yournaling/build-cache, options: mode=max } }`.
  - `proxy: { ssl: true, app_port: 80, healthcheck: { path: /up } }` (host set per-destination).
  - `aliases: { console: "app exec -i -- bin/rails console", shell: "app exec -i -- bash", logs: "app logs -f", dbc: "app exec -i -- bin/rails dbconsole" }` (define **once**).
  - `asset_path: /app/public/assets`, `boot: { limit: 1, wait: 2 }`, `allow_empty_roles: false`.
  - `env.clear` shared: `RAILS_LOG_TO_STDOUT=1`, `RAILS_SERVE_STATIC_FILES=true`,
    `GEOAPIFY_API_URL`, `AMAZON_S3_BUCKET_NAME`.
  - `env.secret` shared: `RAILS_SECRET_KEY_BASE`, `YOURNALING_DB_USERNAME`,
    `YOURNALING_DB_PASSWORD`, `GEOAPIFY_API_KEY`, `AMAZON_S3_ACCESS_KEY_ID`,
    `AMAZON_S3_SECRET_ACCESS_KEY`.
- **`config/deploy.staging.yml`** — the only destination for now:
  - `servers.web.hosts: [<STAGING_HOST>]` — single host, **no `job` role**.
  - `proxy.host: staging.yournaling.com` (decide the real hostname).
  - `env.clear`: `RAILS_ENV=staging`, `SOLID_QUEUE_IN_PUMA=true`, `WEB_CONCURRENCY=1`,
    `JOB_CONCURRENCY=1`, `YOURNALING_HOST=staging.yournaling.com`,
    plus the four DB URLs pointing at the accessory on the Kamal docker network:
    `YOURNALING_DB_URL=postgres://yournaling@yournaling-db:5432/yournaling`,
    `YOURNALING_CABLE_DB_URL=…/yournaling_cable`, `…CACHE…=…/yournaling_cache`,
    `…QUEUE…=…/yournaling_queue`.
    *(Password comes from `env.secret`; if URLs must embed it, build them in `.kamal/secrets`
    instead and list them under `env.secret`.)*
  - `accessories.db`:
    ```yaml
    accessories:
      db:
        image: postgres:17
        host: <STAGING_HOST>
        port: "127.0.0.1:5432:5432"          # localhost-only
        env:
          clear: { POSTGRES_USER: yournaling, POSTGRES_DB: yournaling }
          secret: [ POSTGRES_PASSWORD ]
        directories: [ "/data/postgres:/var/lib/postgresql/data" ]
        files:
          - config/postgres/init-solid-dbs.sql:/docker-entrypoint-initdb.d/10-solid-dbs.sql
    ```
    `init-solid-dbs.sql` = `CREATE DATABASE yournaling_cable OWNER yournaling;` (+ `_cache`,
    `_queue`). Only runs on first init of an empty data dir. (Alternatively let
    `bin/rails db:prepare` create them — the Postgres superuser can — and skip the init file.)
  - `volumes`: only needed if any ActiveStorage falls back to Disk. AS primary is S3, so
    likely omit. If kept: `[ "/data/storage:/app/storage" ]`.

### `.kamal/secrets`
1Password adapter, one `kamal secrets fetch`, then `kamal secrets extract` per var. Use
`NAME=$(...)` (shell), not `NAME: $(...)` (YAML). Vault item: **`yournaling.com/Staging`**.
Vars: `KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`, `RAILS_SECRET_KEY_BASE`
(`SecureRandom.hex(64)`), `YOURNALING_DB_USERNAME`, `YOURNALING_DB_PASSWORD`,
`POSTGRES_PASSWORD` (= the DB password), `GEOAPIFY_API_KEY`, `AMAZON_S3_ACCESS_KEY_ID`,
`AMAZON_S3_SECRET_ACCESS_KEY`. Keep only this template in git (no raw creds); `.gitignore` any
resolved `.kamal/secrets.*`.

### GitHub Actions — `.github/workflows/deploy_staging.yml`
- Trigger: `workflow_dispatch` (optional `ref` input). **Later:** add
  `push: { branches: [main] }` for auto-deploy on merge — leave a commented block + TODO.
- Permissions: `contents: read`, `packages: write` (GHCR via `GITHUB_TOKEN`),
  `id-token: write` (future OIDC).
- Steps (single job, or `build` + `deploy` with `needs:`):
  1. `actions/checkout@v7`.
  2. `ruby/setup-ruby@v1` with `bundler-cache: true`, `BUNDLE_WITH: deploy` so `bin/kamal` is
     available.
  3. `docker/setup-buildx-action`; `docker/login-action` → `ghcr.io` with `${{ github.actor }}` /
     `${{ secrets.GITHUB_TOKEN }}`.
  4. Add SSH key from `secrets.SSH_PRIVATE_KEY` (`webfactory/ssh-agent` or manual).
  5. Export deploy env from **GitHub Actions secrets** (not 1Password in CI, unless a
     service-account token is added): `KAMAL_REGISTRY_PASSWORD`, `RAILS_SECRET_KEY_BASE`,
     `YOURNALING_DB_*`, `POSTGRES_PASSWORD`, `AMAZON_S3_*`, `GEOAPIFY_API_KEY`.
  6. `bin/kamal deploy -d staging` (Kamal builds, pushes with the git SHA, uses the registry
     cache, then deploys). For a build-only run on non-main refs: `bin/kamal build push -d staging`.
- Set a GitHub **Environment** `staging` (URL, optional protection rules) and scope the secrets to it.

### Local build / test (document in README + here)
```bash
# native-arch smoke test
docker build -t yournaling:local .
docker run --rm -p 3000:80 \
  -e RAILS_ENV=staging -e RAILS_SERVE_STATIC_FILES=true \
  -e RAILS_SECRET_KEY_BASE=dev-dummy \
  -e YOURNALING_HOST=localhost \
  -e YOURNALING_DB_URL=postgres://postgres@host.docker.internal:5432/yournaling \
  -e YOURNALING_CABLE_DB_URL=postgres://postgres@host.docker.internal:5432/yournaling_cable \
  -e YOURNALING_CACHE_DB_URL=postgres://postgres@host.docker.internal:5432/yournaling_cache \
  -e YOURNALING_QUEUE_DB_URL=postgres://postgres@host.docker.internal:5432/yournaling_queue \
  -e AMAZON_S3_ACCESS_KEY_ID=x -e AMAZON_S3_SECRET_ACCESS_KEY=x -e AMAZON_S3_BUCKET_NAME=x \
  -e GEOAPIFY_API_KEY=x -e GEOAPIFY_API_URL=https://api.geoapify.com \
  yournaling:local

# production-parity amd64 build
docker buildx build --platform linux/amd64 -t yournaling:amd64 --load .

# via Kamal (uses deploy.yml builder config)
bin/kamal build push -d staging     # build + push to GHCR
```
Optional `docker-compose.yml` (app + `postgres:17` with the four DBs) for local integration
testing — not required for deploy.

---

## 4. Implementation checklist — staging

**Done (this PR — `README_BUILD_AND_DEPLOY.markdown` is the runbook):**

- [x] **Gemfile:** `kamal` moved to `group :deploy` (`require: false`); `thruster` +
      `aws-sdk-s3` added in `group :staging, :production` (`require: false`); `Gemfile.lock`
      updated; CI `BUNDLE_WITHOUT` extended with `deploy`. Binstubs regenerated.
- [x] `bin/docker-entrypoint` — jemalloc preload + `db:prepare` (all four DBs) on server boot.
- [x] `Dockerfile` (ruby:4.0.6-slim, Thruster `CMD`, libvips + libpoppler-glib8 +
      postgresql-client runtime, build-essential/libpq-dev/git/pkg-config build stage,
      non-root, no DB-URL ARG) + `.dockerignore`. No Node — assets are plain Propshaft.
      **Built & run-tested on OrbStack** (arm64): `docker build` OK, entrypoint creates the
      four DBs, `GET /` → 200, `GET /alive` → 200. `Gemfile.lock` gained `aarch64-linux`.
- [x] **DB URL handling = approach (b):** the four `YOURNALING_*_DB_URL` are no longer
      `required:`; they compose from `YOURNALING_DB_{HOST,PORT,NAME,USERNAME,PASSWORD}`.
- [x] `config/deploy.yml` (shared) + `config/deploy.staging.yml` (destination) — single
      `aliases`, ENV names match `AppConf`, `SOLID_QUEUE_IN_PUMA=true`, no `job` role,
      `postgres:17` accessory. Validated with `bin/kamal config -d staging`.
- [x] Solid DB creation: `bin/rails db:prepare` in the entrypoint creates `_cable` / `_cache`
      / `_queue` — no init SQL file needed.
- [x] `.kamal/secrets` — committed template (1Password block + plain-ENV fallthrough); no
      real values. (Creating the actual 1Password item is still open.)
- [x] `config.secret_key_base` wired from `AppConf.rails_secret_key_base` in `production.rb`
      (Rails only reads `SECRET_KEY_BASE`/credentials otherwise — staging wouldn't boot).
- [x] `Rack::Timeout` `service_timeout` coerced with `.to_i` in `application.rb` (an ENV
      `RACK_TIMEOUT` arrives as a String and Rack::Timeout rejected it → boot crash).
- [x] `compose.yaml` — `docker compose up --build` runs the image + a throwaway Postgres for
      local browser testing; on OrbStack the app is at `https://yournaling.orb.local` with a
      trusted cert (so `force_ssl` + secure cookies work and login is testable). Verified:
      `/` `/login` `/register` `/example` → 200.
- [x] `/alive` liveness route added for the Kamal proxy healthcheck (`/up` queries the DB and
      503s until a `User` exists, so it can't gate a first deploy). `/up` + `/alive` excluded
      from `force_ssl` redirect and host authorization.
- [x] SMTP wired in `production.rb` from `AppConf` (`SMTP_*` / `MAILER_FROM` registered);
      delivery stays off until `SMTP_ADDRESS` is set.
- [x] `assets:precompile` verified in the `production` env with `SECRET_KEY_BASE_DUMMY=1`
      (`register` now falls back to defaults under that flag) — writes
      `public/assets/.manifest.json`.
- [x] `.github/workflows/deploy_staging.yml` — `workflow_dispatch`; commented `push: [main]`.
- [x] Full `rake ci` green (lint / security / checks / 1372 specs).

**Still open before a first deploy (needs infra / secrets — see also §6):**

- [ ] Set GitHub Actions secrets + `staging` Environment: `SSH_PRIVATE_KEY`,
      `RAILS_SECRET_KEY_BASE`, `YOURNALING_DB_PASSWORD`, `AMAZON_S3_ACCESS_KEY_ID`,
      `AMAZON_S3_SECRET_ACCESS_KEY`, `GEOAPIFY_API_KEY`; variable `STAGING_HOST`.
      (`GITHUB_TOKEN` covers GHCR.)
- [ ] Create the 1Password item for local `kamal` runs (or just export the vars).
- [ ] Run an **amd64** build (`bin/kamal build push -d staging` or
      `docker buildx build --platform linux/amd64`) — only the native arm64 build has been
      exercised. (SolidQueue-in-Puma supervisor also still to be observed running a job.)
- [ ] Provision the staging server (adapt `bin/provision` from `origin/kamal`): Ubuntu 22+,
      Docker, a Postgres data dir, swap, fail2ban; firewall 22/80/443; DNS
      `staging.yournaling.com` → host. **The old Hetzner box / IPs are no longer ours —
      provision fresh.**
- [ ] First deploy: set `STAGING_HOST` + secrets → `bin/kamal config -d staging` →
      `bin/kamal setup -d staging` → `bin/kamal app logs -d staging` → verify
      `https://staging.yournaling.com` + Let's Encrypt cert + `/up` green.
- [ ] Backups: `pg_dump` of all four DBs → S3 (host cron or a `postgres-backup-s3`-style
      accessory); document restore; confirm the Postgres volume survives redeploy.
- [ ] Pick an SMTP provider for staging (or leave mail disabled).
- [ ] **Follow-up:** enable `push: [main]` in the workflow for auto-deploy once staging is proven.

---

## 5. Production rollout (deferred)

Do **not** build these now — capture them so staging choices don't paint us into a corner.

- **`config/deploy.production.yml`** destination: multiple `servers.web.hosts`, a dedicated
  `servers.job` role (`cmd: bin/jobs`, `SOLID_QUEUE_IN_PUMA=false`), `WEB_CONCURRENCY > 1`,
  `JOB_CONCURRENCY` tuned, `boot.limit` for rolling deploys.
- **Database:** dedicated Postgres server(s) or a managed service (Hetzner/RDS/Crunchy). Point
  the four `YOURNALING_*_DB_URL` at it; **remove the `db` accessory**. Consider separate
  hosts/instances for `primary` vs the Solid* databases, and a read replica for `primary` if
  reporting/Blazer load warrants it.
- **Postgres tuning:** revive `config/postgres_production.conf` (from `origin/kamal`) via a
  `files:` mount, sized to the real instance.
- **Backups at scale:** WAL archiving / PITR (e.g. pgBackRest or the managed provider's
  snapshots), not just nightly `pg_dump`. Documented restore drill.
- **Secrets:** 1Password vault item `yournaling.com/Production`; OIDC from GitHub Actions
  instead of long-lived SSH keys where possible.
- **Workflow:** promote staging → production (manual `workflow_dispatch` with an environment
  input, or a tag-triggered job), protection rules / required reviewers on the `production`
  Environment.
- **Domain:** `yournaling.com` (apex + `www`) → production; keep `staging.yournaling.com`
  pointed at staging.
- **`db/seeds.rb`:** the production seed block (admin user + demo data) from `origin/kamal` —
  review separately, likely a one-shot `kamal app exec`, not part of `db:prepare`.
- **Zero-downtime:** verify Kamal proxy rolling deploy with `>1` web host; check migration
  safety (strong_migrations is not in the Gemfile — `fix-db-schema-conflicts` only sorts the
  schema).

---

## 6. Open questions / risks

- **Staging server:** does the old Hetzner box (188.245.99.209) / SSH still exist? Reuse it for
  staging, or provision a fresh small instance? What hostname — `staging.yournaling.com`?
- **`aws-sdk-s3` + `thruster` are missing from the Gemfile** — both are hard blockers; add them
  in the first implementation PR.
- **Four `YOURNALING_*_DB_URL` are `required: production_env`** — pick approach (a) or (b) from
  §4 before writing `deploy.yml`.
- **SMTP is unconfigured** — staging will raise on any mail send until a provider + settings are
  added. Decide: real provider, or disable delivery on staging.
- **GHCR namespace:** `ghcr.io/mediafinger/yournaling` — user vs org, and is the package
  visibility/permission set for GHA `packages: write`?
- **First amd64 build under QEMU on the Mac is slow (~10–20 min)** — lean on the registry build
  cache and/or always build in GHA.
- **dartsass in the image:** confirm `assets:precompile` triggers `dartsass:build`; if not, add
  an explicit build step in the Dockerfile.
- **Thruster + Kamal proxy:** both speak HTTP — ensure `proxy.app_port: 80`, Thruster TLS off
  (Kamal proxy terminates TLS), no double gzip.
- **`bin/docker-entrypoint` running `db:prepare` every boot** on a single container is fine;
  revisit when there is more than one web container (only one should migrate).
