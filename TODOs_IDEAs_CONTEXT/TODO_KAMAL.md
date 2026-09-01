# TODO — Kamal 2 Deployment

Status: **planning** · Branch: `kamal2` (worktree, off `main`) · Date: 2026-09-01

References:
- Website: https://kamal-deploy.org/
- Docs (v2.x): https://kamal-deploy.org/docs/installation/
- Source: https://github.com/basecamp/kamal
- GHA pattern the old branch pointed at: https://jetthoughts.com/blog/automate-your-deployments-with-kamal-2-github-actions-devops-development/

---

## 1. What exists today

### On `main`
- `gem "kamal"` is already in the `Gemfile` (inside `group :development, :test` — see [Gemfile](../Gemfile) line ~66). Nothing else Kamal-related is committed.
- No `Dockerfile`, no `config/deploy.yml`, no `.kamal/`, no `.dockerignore`, no deploy workflow.
- Stack: Ruby **4.0.6** (`.ruby-version`), Rails `~> 8.1.3`, Puma `~> 8.0`, Propshaft + dartsass + importmap, Slim, ViewComponent.
- DB: primary **PostgreSQL** (`pg ~> 1.1`); SolidCache / SolidQueue / SolidCable on **SQLite files under `storage/`** (see [config/database.yml](../config/database.yml)).
- Jobs: `bin/jobs` runs the SolidQueue supervisor.
- Image processing: `image_processing ~> 2.0` + `ruby-vips` → needs system **libvips** (CI also installs `libpoppler-glib8`).
- ActiveStorage → **Amazon S3** (`amazon_s3` service, region `eu-central-1`), config via `AppConf.amazon_s3_*`.
- Geocoding → Geoapify (`AppConf.geoapify_api_*`).
- Health check route exists: `GET /up` → `health#show` (Kamal's default readiness probe).
- `config/environments/production.rb` already sets `config.assume_ssl = true` and `config.force_ssl = true`; the `/up` exclusion lines for `ssl_options` and `host_authorization` are **commented out** and should be enabled.
- Config is centralised in `config/app_conf.rb` (`AppConf`), reading ENV. Relevant keys:
  `yournaling_db_url` / `yournaling_db_{host,name,password,port,username,timeout_seconds}`,
  `rails_secret_key_base`, `amazon_s3_access_key_id` / `amazon_s3_secret_access_key` / `amazon_s3_bucket_name`,
  `geoapify_api_key` / `geoapify_api_url`. All `required: production_env`.
- CI: `.github/workflows/ci_push_pull_main.yml` (tests/lint only, runs on PR + push to main).

### On the old `origin/kamal` branch (stale — forked 54 commits back at `0c96704`, last commit `8765106`)
Adds a full but **unfinished and partly AI-generated** Kamal 2 setup:

| File | Notes |
|---|---|
| `Dockerfile` | Multi-stage, `ruby:3.3.6-slim`, installs `libvips postgresql-client libjemalloc2`, non-root `rails` uid 1000, `assets:precompile` with `SECRET_KEY_BASE_DUMMY=1`, `ENTRYPOINT bin/docker-entrypoint`, `CMD ["./bin/thrust", "./bin/rails", "server"]`, `EXPOSE 80`. Has a half-baked `YOURNALING_DB_URL` build-ARG block that references an unset `YOURNALING_DB_PASSWORD` — **drop that**, the URL belongs in runtime ENV not the image. |
| `.dockerignore` | Standard Rails 8 generated ignore list — reusable as-is. |
| `bin/docker-entrypoint` | jemalloc preload + `./bin/rails db:prepare` when starting the server. Reusable. |
| `bin/kamal` | Bundler binstub. Reusable (regenerate with `bundle binstubs kamal`). |
| `bin/provision` | Ruby script (from mhenrixon's article) to provision an Ubuntu 22+ host: essentials, `/data/storage` + `/data/postgres` (chown 1000), 2 GB swap, fail2ban. Firewall handled by Hetzner Cloud Firewall. Useful starting point. |
| `config/deploy.yml` | **Contains duplicate keys** (`aliases`, `asset_path` defined twice) and hardcoded values. Roles `web` + `job` both on `188.245.99.209`; proxy `ssl: true`, `host: yournaling.com`, `app_port: 3000`; registry `ghcr.io` with `KAMAL_REGISTRY_USERNAME/PASSWORD`; builder `arch: amd64`, `RUBY_VERSION: 3.3.6`, registry build cache at `ghcr.io/mediafinger/yournaling/build-cache`; `postgres:17` accessory with `/data/postgres` volume; app volume `/data/storage:/app/storage`; rolling `boot: {limit: 10, wait: 2}`. Needs a rewrite, not a cherry-pick. |
| `.kamal/secrets` | 1Password adapter: `kamal secrets fetch --adapter 1password --account … --from yournaling.com/Production …`. **Has YAML-vs-shell syntax bug** — lines use `POSTGRES_DB: $(…)` (colon) instead of `POSTGRES_DB=$(…)`. Fix on rewrite. |
| `.kamal/hooks/*.sample` | Default Kamal sample hooks (pre-build clean-checkout check, pre-deploy GitHub build-status gate, etc.). Keep as `.sample` for now. |
| `.github/workflows/deploy.yml` | **Stub only** — a `name:` and two TODO comments. Nothing implemented. |
| `config/postgres_production.conf` | 844-line generated postgres tuning file, referenced only in a commented-out `files:` block. Skip for now. |
| `Gemfile` / `Gemfile.lock` | Adds `kamal` + `thruster` (both `require: false`). Lock is for the old Ruby 3.3 / gem set — regenerate. |
| `db/seeds.rb` | Adds a `production` seed block (creates admin user + demo team/location/weblink). Out of scope for this task — revisit separately. |
| `config/app_conf.rb`, `config/environments/production.rb`, `bin/dev` | Minor tweaks (enable `/up` SSL/host-auth exclusions, shebang fix). `main` already has most of these. |

There is also an older `origin/dockerize` branch: a plain Rails-8-generated `Dockerfile` (Ruby 3.3.1, `WORKDIR /rails`, `EXPOSE 3000`, no Thruster) + `.dockerignore` + `bin/docker-entrypoint`. Superseded by the `kamal` branch's version.

### The `Kamal_Deployment.markdown` file (untracked, in working dir on `yui-design`)
An AI-written status/checklist doc. Records infra work claimed done:
- Hetzner server obtained, IP **188.245.99.209**; firewall = SSH 22 / HTTP 80 / HTTPS 443 only.
- Domain **yournaling.com** DNS → that IP; nameservers configured.
- SSH configured locally + on server.
- `.kamal/secrets` wired to 1Password: GHCR token, `RAILS_MASTER_KEY`, DB creds stored under `yournaling.com/Production`.
- Docker installed locally (not on CI).

Still open per that doc: Docker on CI, finalised Dockerfile & `deploy.yml` (SSL / storage / DB verified), persistent + backed-up storage and DB (S3 backups), first `kamal setup`.

> ⚠️ Treat the "done" claims as **unverified**. The server may or may not still exist (Q1 answer was "decide later"). Re-check before the first real deploy.

---

## 2. Decisions (from Andy, 2026-09-01)

1. **DB topology:** decide later. Plan documents **both**: default = Postgres 17 as a Kamal **accessory** on the same host with a bind-mounted, off-server-backed volume; alternative = external/managed Postgres (just point `YOURNALING_DB_*` / `DATABASE_URL` at it and drop the accessory).
2. **GitHub Actions workflow:** build **+ push + deploy**, **manually triggered** (`workflow_dispatch`). Since there is no server yet, the **deploy job/step is written but commented out** with an explanatory comment.
3. **Thruster:** **yes** — add the `thruster` gem, container `CMD ["./bin/thrust", "./bin/rails", "server"]`, Kamal proxy → Thruster.
4. **Secrets:** **1Password CLI adapter** for local `kamal` runs; GitHub Actions uses its own Actions secrets/OIDC.
5. Must be possible to **build the image locally** for testing (and optionally dev).
6. No code changes in this task — this file only. Commit it first, then push `kamal2`.

---

## 3. Target design

### Container / image
- Registry: **GHCR** — `ghcr.io/mediafinger/yournaling` (+ build cache `…/yournaling/build-cache`).
- Base: `ruby:4.0.6-slim` (keep `ARG RUBY_VERSION` in sync with `.ruby-version`).
- Build platform: **linux/amd64** (Hetzner is x86-64). Local dev on Apple Silicon → cross-build via `docker buildx --platform linux/amd64` (Kamal's `builder.arch: amd64` handles this automatically; first local build is slow under emulation, hence the registry build cache).
- Runtime packages: `curl libjemalloc2 libvips postgresql-client` (+ `libpoppler-glib8` to match CI's PDF/image support — verify it's needed in prod).
- Build packages (throwaway stage): `build-essential git libpq-dev pkg-config`.
- Non-root `rails` user (uid/gid 1000); `chown` `db log storage tmp`.
- `assets:precompile` at build with `SECRET_KEY_BASE_DUMMY=1` (Propshaft; ensure the dartsass build runs — check `bin/rails assets:precompile` triggers `dartsass:build`).
- `ENTRYPOINT bin/docker-entrypoint` (jemalloc + `db:prepare` on server start), `CMD ["./bin/thrust","./bin/rails","server"]`, `EXPOSE 80`.
- **Do not** bake DB URL / secrets into the image. `RAILS_MASTER_KEY` only needed at runtime (or as a buildx secret if precompile ever needs real creds — it shouldn't).

### `config/deploy.yml` (clean rewrite — not a cherry-pick)
- `service: yournaling`, `image: mediafinger/yournaling`.
- `servers.web.hosts: [<HOST>]`; `servers.job` with `cmd: bin/jobs` (same host for now; note the option to move jobs into Puma via `SOLID_QUEUE_IN_PUMA=true` on a single small box).
- `proxy: { ssl: true, host: yournaling.com, app_port: 80, healthcheck: { path: /up } }` (Thruster listens on 80 in-container).
- `registry: { server: ghcr.io, username: [KAMAL_REGISTRY_USERNAME], password: [KAMAL_REGISTRY_PASSWORD] }`.
- `builder: { arch: amd64, args: { RUBY_VERSION: 4.0.6 }, cache: { type: registry, image: ghcr.io/mediafinger/yournaling/build-cache, options: mode=max } }`.
- `env.clear`: `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES=true`, `WEB_CONCURRENCY`, `JOB_CONCURRENCY`, `SOLID_QUEUE_IN_PUMA=false`, `YOURNALING_DB_HOST` (= `yournaling-db` when using the accessory on the kamal docker network), `YOURNALING_DB_PORT`, `YOURNALING_DB_NAME`, `GEOAPIFY_API_URL`, `AMAZON_S3_BUCKET_NAME`, region.
- `env.secret`: `RAILS_SECRET_KEY_BASE` (or `RAILS_MASTER_KEY` if switching to credentials), `YOURNALING_DB_PASSWORD`, `YOURNALING_DB_USERNAME`, `GEOAPIFY_API_KEY`, `AMAZON_S3_ACCESS_KEY_ID`, `AMAZON_S3_SECRET_ACCESS_KEY`.
  - ⚠️ Reconcile naming: `AppConf` expects `YOURNALING_DB_*` / `AMAZON_S3_*` / `GEOAPIFY_API_*` / `RAILS_SECRET_KEY_BASE`. The old `deploy.yml` used `POSTGRES_*` and `RAILS_MASTER_KEY` — pick one convention and keep app + deploy + 1Password item in sync.
- `volumes: ["/data/storage:/app/storage"]` — persists SolidQueue/Cache/Cable SQLite files **and** any Disk-service ActiveStorage. (AS primary is S3, so this is mainly the Solid* DBs.)
- `accessories.postgres` (default topology): `image: postgres:17`, `host: <HOST>`, `directories: ["/data/postgres:/var/lib/postgresql/data"]`, `env.clear POSTGRES_DB/POSTGRES_USER`, `env.secret POSTGRES_PASSWORD`.
- `aliases`: `console`, `shell`, `logs`, `dbc` (define **once**).
- `asset_path: /app/public/assets`; `boot: { limit: 10, wait: 2 }`; `allow_empty_roles: false`.
- Parameterise the host/domain via a top-of-file anchor or `destination` files if staging is added later.

### `.kamal/secrets`
1Password adapter, one `kamal secrets fetch` call, then `kamal secrets extract` per var. Fix the `NAME=value` (not `NAME:`) shell syntax. Vault item: `yournaling.com/Production`. Vars: `KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`, `RAILS_SECRET_KEY_BASE` (or `RAILS_MASTER_KEY`), `YOURNALING_DB_USERNAME`, `YOURNALING_DB_PASSWORD`, `GEOAPIFY_API_KEY`, `AMAZON_S3_ACCESS_KEY_ID`, `AMAZON_S3_SECRET_ACCESS_KEY`. Keep `.kamal/secrets*` out of git except this template (already git-safe — no raw creds).

### GitHub Actions — `.github/workflows/deploy.yml`
- Trigger: `workflow_dispatch` only (inputs: optional `ref`/tag; later: environment).
- Permissions: `contents: read`, `packages: write` (GHCR push via `GITHUB_TOKEN`), `id-token: write` (future OIDC).
- Job `build-and-push`:
  - checkout, `docker/setup-buildx-action`, `docker/login-action` → `ghcr.io` with `${{ github.actor }}` / `${{ secrets.GITHUB_TOKEN }}`.
  - Set up Ruby (`ruby/setup-ruby`, bundler cache) so `bin/kamal` is available.
  - `bin/kamal build push` (Kamal drives buildx, tags with git SHA, uses the registry cache) — **or** a direct `docker/build-push-action` with `platforms: linux/amd64`, `cache-from/to: type=registry,ref=…/build-cache`. Prefer `kamal build push` to keep one source of truth.
  - Needs `RAILS_MASTER_KEY` / registry creds only if the build requires them (it shouldn't — dummy secret key base).
- Job `deploy` (**commented out** — "no server yet"):
  - `needs: build-and-push`, adds SSH key from `secrets.SSH_PRIVATE_KEY`, `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, 1Password service-account token (or plain Actions secrets instead of 1Password in CI), then `bin/kamal deploy --skip-push` (image already pushed).
  - Left in the file as a fully-written but block-commented job with a `# TODO: enable once the production server exists and secrets are configured` note.

### Local build (testing / optional dev)
Document in the deploy doc / README:
```
# plain docker build (native arch, quick smoke test)
docker build -t yournaling:local .
docker run --rm -p 3000:80 \
  -e RAILS_SECRET_KEY_BASE=dev-dummy -e RAILS_SERVE_STATIC_FILES=true \
  -e YOURNALING_DB_URL=postgres://user:pass@host.docker.internal:5432/yournaling \
  yournaling:local

# production-parity amd64 build (what Kamal/GHA produce)
docker buildx build --platform linux/amd64 -t yournaling:amd64 --load .

# via Kamal (uses deploy.yml builder config, no push)
bin/kamal build dev        # builds + runs locally
bin/kamal build push       # build + push to GHCR only
```
Optionally add a `docker-compose.yml` (app + `postgres:17`) purely for local integration testing — not required for deploy.

---

## 4. Implementation checklist (next branch / PR — NOT this task)

- [ ] Move `gem "kamal"` out of `:development, :test` into a dedicated `:deploy`/top-level line; add `gem "thruster", require: false`. `bundle install`, commit `Gemfile.lock` (Ruby 4.0.6 gem set).
- [ ] `bundle binstubs kamal` → `bin/kamal`; add `bin/docker-entrypoint` (from old branch, unchanged).
- [ ] Add `Dockerfile` (Ruby 4.0.6, Thruster CMD, libvips/pdf deps, drop the broken DB-URL ARG block) + `.dockerignore` (from old branch).
- [ ] `kamal init`, then write `config/deploy.yml` from the target design above (single `aliases`, no dup keys, ENV names matching `AppConf`).
- [ ] Add `.kamal/secrets` (1Password adapter, fixed `NAME=value` syntax); create/verify the `yournaling.com/Production` 1Password item; `.gitignore` any resolved secret files.
- [ ] Enable the two `/up` exclusion lines in `config/environments/production.rb` (`ssl_options`, `host_authorization`); double-check `config.hosts` / host authorization allows `yournaling.com`.
- [ ] Confirm `assets:precompile` in the image also compiles dartsass (`app/assets/builds`), and the Propshaft manifest is present.
- [ ] Add `.github/workflows/deploy.yml` — `workflow_dispatch`, build+push job active, deploy job written but commented out.
- [ ] Local verification: `docker buildx build --platform linux/amd64 … --load` succeeds; container boots against a local Postgres; `/up` returns 200; assets served; a SolidQueue job runs.
- [ ] Decide DB topology (accessory vs managed) — update `deploy.yml` accordingly.
- [ ] Provision server (adapt `bin/provision`): `/data/storage` + `/data/postgres` (chown 1000:1000), 2 GB swap, fail2ban, Docker; Hetzner Cloud Firewall = 22/80/443; DNS `yournaling.com` → host.
- [ ] Set GH Actions secrets: `SSH_PRIVATE_KEY`, registry creds (or rely on `GITHUB_TOKEN`), `RAILS_MASTER_KEY`/`RAILS_SECRET_KEY_BASE`, 1Password service-account token (if used in CI).
- [ ] First deploy: `op signin` → `kamal config` (dry run) → `kamal setup` → `kamal app exec -i "bin/rails db:prepare"` → `kamal details` / `kamal app logs` → verify `https://yournaling.com` + valid Let's Encrypt cert.
- [ ] Uncomment the GHA deploy job.
- [ ] Persistence & backups: confirm `/data/postgres` + `/data/storage` survive `kamal remove`/redeploy; add Postgres→S3 backup (e.g. `postgres-backup-s3` accessory or a host cron); document restore.
- [ ] Optionally add `config/postgres_production.conf` tuning + `files:` mount once the baseline works.
- [ ] Revisit `db/seeds.rb` production seeding separately (out of scope here).
- [ ] Update `Kamal_Deployment.markdown` / README with the local-build + deploy runbook; delete stale claims.

## 5. Open questions / risks

- Does the Hetzner server (188.245.99.209) still exist and is SSH still valid? (Q1 deferred — verify before provisioning.)
- ENV-name convention: standardise on `YOURNALING_DB_*` + `RAILS_SECRET_KEY_BASE` (matches `AppConf`) vs `POSTGRES_*` + `RAILS_MASTER_KEY` (old branch / Rails default). Recommend the `AppConf` names to avoid touching app code.
- `image: mediafinger/yournaling` — confirm the GHCR namespace/owner (`mediafinger` user vs an org).
- SolidQueue/Cache/Cable on SQLite in `/app/storage` means the **job and web containers must share the same host + volume** (or move Solid* to Postgres). Keep single-host until that's reworked.
- Thruster + Kamal proxy: both handle HTTP — ensure `app_port: 80`, Thruster TLS disabled (Kamal proxy terminates TLS), and no double gzip.
- First amd64 build under QEMU on the Mac is slow (~10-20 min) — rely on the registry build cache and/or run the build in GHA.
