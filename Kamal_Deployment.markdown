# Kamal Deployment

## TODOs

- [x] server
  - [x] get a server
  - [x] sertup server firewall to only allow SSH 22, HTTP 80, HTTPS 443
- [x] domain yournaling.com
  - [x] ensure DNS records point to Hetzner server 188.245.99.209
  - [x] configure nameservers
- [x] configure SSH
  - [x] locally
  - [x] on server
- [ ] install Docker
  - [x] locally
  - [ ] on CI
- [ ] customized Dockerfile
- [ ] customized _config/deploy.yml_
  - [ ] ensure SSL certificate works
  - [ ] ensure storage configuration works
  - [ ] ensure database configuration works
- [x] working _.kamal/secrets_
  - [x] create GitHub Container Registry Token
  - [x] make GHCR token available over 1Password
  - [x] create RAILS_MASTER_KEY
  - [x] make GHCR token available over 1Password
- [ ] permanent storage
  - [ ] ensure storage is persisted / persistent
  - [ ] ensure database is persisted / persistent
  - [ ] ensure storage is backed up to S3
  - [ ] ensure database is backed up to S3

## Antigravity: current status

### Application Architecture & Core Stack
- **Framework & Runtime**: Ruby 3.3.6 and Rails 8.0.1.
- **Web Application Server**: Puma (~> 6.3) fronted by Thruster (`thruster` gem) for HTTP/2 asset caching, compression, and X-Sendfile acceleration (listening on port 80 inside the container).
- **Frontend & Asset Pipeline**: Propshaft asset pipeline, DartSASS (`dartsass-rails`), Importmaps (`importmap-rails`), Hotwire (Stimulus & Turbo), Slim HTML templates (`slim-rails`), and `view_component`.
- **Database Layer**:
  - **Primary Database**: PostgreSQL (`pg` gem), configured to connect to PostgreSQL 17.
  - **Solid Infrastructure Stack**: `solid_cache`, `solid_queue`, and `solid_cable` are configured using local SQLite3 databases saved under `/app/storage`.
- **External & Background Dependencies**:
  - Image processing via `ruby-vips` (requires system library `libvips`).
  - ActiveStorage backed by Amazon S3 (`amazon_s3` configuration in `config/storage.yml`).
  - Geocoding API via Geoapify (`GEOAPIFY_API_KEY`).
  - Background job worker process (`bin/jobs` running SolidQueue).

### Deployment Readiness via Kamal
- **Containerization (`Dockerfile`)**: Production multi-stage Dockerfile is fully configured using `ruby:3.3.6-slim`, installing essential packages (`libvips`, `postgresql-client`, `libjemalloc2`), running as non-root user `rails` (UID 1000), precompiling assets, and using `./bin/thrust ./bin/rails server` as entrypoint CMD.
- **Kamal Configuration (`config/deploy.yml`)**:
  - Service named `yournaling`, image `mediafinger/yournaling` hosted on GitHub Container Registry (`ghcr.io`).
  - Configured two server roles (`web` and `job`) pointing to host `188.245.99.209`.
  - SSL proxy enabled via Kamal Proxy for `yournaling.com`.
  - Accessory `postgres` (PostgreSQL 17) configured with persistent mount `/data/postgres`.
  - Persistent volume configured for SQLite databases and local uploads: `/data/storage:/app/storage`.
  - Zero-downtime rolling deploys configured with asset path bridging (`/app/public/assets`).
- **Secrets Management (`.kamal/secrets`)**: Integrated with 1Password CLI adapter (`kamal secrets fetch --adapter 1password`) to dynamically pull registry tokens (`KAMAL_REGISTRY_PASSWORD`), `RAILS_MASTER_KEY`, and PostgreSQL user credentials.

---

## Antigravity: missing steps

### 1. Initial Deployment Checklist (`kamal setup`)

- [ ] **Local Environment Prep & Secret Verification**:
  - [ ] Ensure Docker daemon is running locally.
  - [ ] Log in to 1Password CLI locally (`op signin`) so `.kamal/secrets` can resolve secrets dynamically.
  - [ ] Verify SSH access from your local machine to the target server `188.245.99.209` (`ssh root@188.245.99.209`).
  - [ ] Confirm DNS records for `yournaling.com` point to `188.245.99.209` and server firewall rules allow SSH (22), HTTP (80), and HTTPS (443).
- [ ] **Kamal Configuration Dry Run**:
  - [ ] Run `kamal config` to inspect the generated configuration and ensure all environment variables and secrets resolve correctly.
- [ ] **Initial Provisioning & Deployment Execution**:
  - [ ] Execute initial setup: `kamal setup`
    - *This automatically boots the server dependencies, logs into GHCR, boots the PostgreSQL accessory (`postgres:17`), builds and pushes the Docker container, provisions Kamal Proxy with Let's Encrypt SSL, and starts the `web` and `job` containers.*
- [ ] **Database & System Verification**:
  - [ ] Execute initial database setup/migration if needed: `kamal app exec -i "bin/rails db:prepare"`
  - [ ] Verify container deployment status: `kamal details`
  - [ ] Inspect container logs to confirm health: `kamal app logs` and `kamal accessory logs postgres`
  - [ ] Verify SSL certificate and application availability in browser at `https://yournaling.com`.

### 2. Subsequent Redeployment Checklist (`kamal deploy`)

- [ ] **Pre-Deployment Preparation**:
  - [ ] Commit all tested changes to git.
  - [ ] Ensure local 1Password session is active (`op signin`).
- [ ] **Deploying Code Updates**:
  - [ ] Run deployment command: `kamal deploy`
    - *Kamal will automatically build a new container image tagged with the git commit SHA, push it to `ghcr.io`, pull it on `188.245.99.209`, run database migrations via entrypoint script, bridge static assets, gracefully swap proxy routing, and stop old containers.*
- [ ] **Useful Operations & Post-Deployment Monitoring**:
  - [ ] Tail live app logs: `kamal app logs -f`
  - [ ] Access production Rails console: `bin/kamal console` (or `kamal app exec -i "bin/rails console"`)
  - [ ] Access production DB console: `bin/kamal dbc`
  - [ ] Update environment variables or secrets without code changes: edit 1Password / `.kamal/secrets` -> run `kamal env push` -> run `kamal app reboot`
  - [ ] Roll back to previous release if an issue occurs: `kamal rollback <GIT_COMMIT_SHA>`
