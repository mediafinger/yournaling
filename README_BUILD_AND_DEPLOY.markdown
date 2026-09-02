# Build & Deploy

Containerised deployment with **Kamal 2**. Target: a **staging** environment on a
**single server** (Puma + SolidQueue-in-Puma + a PostgreSQL 17 accessory holding all
four databases). Production is deferred — see `TODOs_IDEAs_CONTEXT/TODO_KAMAL.md` §5.

> Status: not yet deployed. No server exists, no GitHub/1Password secrets are set.
> The image has not been built on a real Docker host yet.

---

## 1. Requirements

| Where | Needs |
|---|---|
| Workstation (manual deploy) | Docker, Ruby 4.0.6 + `bundle install`, `bin/kamal`, SSH access to the server, the `op` 1Password CLI + `kamal secrets` extension (optional, for the 1Password path) |
| CI (GitHub Actions) | nothing extra — `.github/workflows/deploy_staging.yml` installs Ruby + Buildx |
| Server | Ubuntu 22+, Docker Engine, SSH; ports 22/80/443 open; a data dir for Postgres; DNS `staging.yournaling.com` → server IP |
| Registry | GitHub Container Registry — `ghcr.io/mediafinger/yournaling` (+ `-build-cache`) |
| Storage | An S3 bucket `yournaling-staging` (eu-central-1) + IAM credentials |

---

## 2. Environment variables

### Set on the deploy target via `config/deploy.yml` (non-secret, `env.clear`)

| Var | Value | Notes |
|---|---|---|
| `RAILS_ENV` | `staging` | destination file |
| `RAILS_LOG_TO_STDOUT` | `1` | |
| `RAILS_SERVE_STATIC_FILES` | `true` | Thruster serves `/public` |
| `YOURNALING_PORT` | `3000` | Puma port; Thruster's default target |
| `WEB_CONCURRENCY` / `JOB_CONCURRENCY` | `1` | |
| `SOLID_QUEUE_IN_PUMA` | `true` | no separate job container |
| `YOURNALING_HOST` | `staging.yournaling.com` | |
| `YOURNALING_DB_HOST` | `yournaling-db` | the accessory container name on the Kamal network |
| `YOURNALING_DB_NAME` | `yournaling` | secondaries derived: `yournaling_cache/_cable/_queue` |
| `YOURNALING_DB_USERNAME` | `yournaling` | |
| `YOURNALING_DB_PORT` | `5432` | |
| `YOURNALING_DB_TIMEOUT_SECONDS` | `5` | |
| `AMAZON_S3_BUCKET_NAME` | `yournaling-staging` | |
| `GEOAPIFY_API_URL` | `https://api.geoapify.com` | |

The four `YOURNALING_*_DB_URL` are **composed automatically** from the parts above
(`AppConf`). Set them explicitly only to point at an external/managed database.

### Secrets — resolved through `.kamal/secrets`

| Var | Used for |
|---|---|
| `KAMAL_REGISTRY_USERNAME` | GHCR login user (GitHub actor in CI; your GitHub username locally) |
| `KAMAL_REGISTRY_PASSWORD` | GHCR login (`GITHUB_TOKEN` in CI; a PAT with `write:packages` locally) |
| `RAILS_SECRET_KEY_BASE` | Rails — `ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'` |
| `YOURNALING_DB_PASSWORD` | app → Postgres. **Must equal `POSTGRES_PASSWORD`** |
| `POSTGRES_PASSWORD` | Postgres accessory superuser |
| `AMAZON_S3_ACCESS_KEY_ID` / `AMAZON_S3_SECRET_ACCESS_KEY` | ActiveStorage |
| `GEOAPIFY_API_KEY` | geocoding |

Optional (mail; delivery stays **off** while `SMTP_ADDRESS` is unset):
`SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`, `MAILER_FROM`.

### CI-only

- Repo/Environment **secrets**: `RAILS_SECRET_KEY_BASE`, `YOURNALING_DB_PASSWORD`,
  `AMAZON_S3_ACCESS_KEY_ID`, `AMAZON_S3_SECRET_ACCESS_KEY`, `GEOAPIFY_API_KEY`,
  `SSH_PRIVATE_KEY`.
- Repo/Environment **variable**: `STAGING_HOST` (server IP/hostname).
- `GITHUB_TOKEN` is provided automatically (used as the GHCR password).

---

## 3. One-time setup

```bash
# 0. Gems
bundle install

# 1. Server: provision Docker + a Postgres data volume, open 22/80/443,
#    point DNS staging.yournaling.com -> server IP.

# 2. Secrets: create the 1Password item "Yournaling/Staging" (or export the
#    vars in your shell), and set the GitHub Actions secrets/vars from §2.

# 3. Tell Kamal the host (either edit config/deploy.staging.yml or export):
export STAGING_HOST=<server-ip>
export KAMAL_REGISTRY_PASSWORD=<ghcr-pat>   # + the other secrets from §2

# 4. Bootstrap the server (installs Docker if missing, boots kamal-proxy,
#    the DB accessory, and the first release):
bin/kamal setup -d staging
```

---

## 4. Build & deploy

```bash
# Full build + push + deploy
bin/kamal deploy -d staging

# Build & push only (no release)
bin/kamal build push -d staging

# Render/validate the config without touching anything
bin/kamal config -d staging
```

### Local image build (no server needed)

```bash
# native arch, quick smoke test
docker build -t yournaling:local .

# production-parity linux/amd64 (what Kamal/CI produce)
docker buildx build --platform linux/amd64 -t yournaling:amd64 --load .

# run it against a local Postgres
docker run --rm -p 8080:80 \
  -e RAILS_ENV=staging -e RAILS_SERVE_STATIC_FILES=true -e YOURNALING_PORT=3000 \
  -e RAILS_SECRET_KEY_BASE=dev-dummy -e YOURNALING_HOST=localhost \
  -e YOURNALING_DB_HOST=host.docker.internal -e YOURNALING_DB_NAME=yournaling \
  -e YOURNALING_DB_USERNAME=postgres -e YOURNALING_DB_PASSWORD=postgres \
  -e YOURNALING_DB_TIMEOUT_SECONDS=5 \
  -e AMAZON_S3_ACCESS_KEY_ID=x -e AMAZON_S3_SECRET_ACCESS_KEY=x \
  -e AMAZON_S3_BUCKET_NAME=x -e GEOAPIFY_API_KEY=x \
  yournaling:local
# -> http://localhost:8080/up
```

### Via GitHub Actions

`Actions → deploy-staging → Run workflow` (manual `workflow_dispatch`). Requires the
secrets/vars from §2. To auto-deploy on merge to `main`, uncomment the `push:` block
in `.github/workflows/deploy_staging.yml`.

---

## 5. Common operations

```bash
bin/kamal app logs -d staging -f          # tail logs
bin/kamal console -d staging              # rails console
bin/kamal shell -d staging                # bash in the container
bin/kamal dbc -d staging                  # rails dbconsole
bin/kamal app exec -d staging "bin/rails db:prepare"   # migrate all 4 DBs
bin/kamal rollback -d staging <version>   # roll back
bin/kamal accessory logs db -d staging    # Postgres accessory
```

The entrypoint runs `bin/rails db:prepare` on every server boot, so ordinary
deploys migrate automatically.

---

## 6. What's still open

- Provision a staging server; set `STAGING_HOST` and the secrets.
- Decide the real staging hostname (`staging.yournaling.com` assumed).
- Postgres backups: `pg_dump` of all four DBs → S3 (cron or accessory); test restore.
- Confirm the image builds on a real Docker host and `/up` returns 200.
- SMTP provider for staging (or leave mail delivery disabled).
- Then: enable the `push: [main]` trigger for auto-deploy.
