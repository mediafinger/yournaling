# Analysis of Status Quo — Yournaling

This document provides a comprehensive technical analysis of the current architecture, data models, controllers, view layer, background infrastructure (the Solid stack), functioning features, missing pieces, and architectural tradeoffs in the Yournaling codebase.

---

## 1. Executive Summary & Architecture Overview

Yournaling is designed as a multi-tenant travel journaling platform where **Users** belong to **Teams** (or travel groups), creating and managing **Memories** composed of granular content pieces (**Locations**, **Pictures**, **Thoughts**, and **Weblinks**).

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                           Routing & Controllers                         │
 │   • / (Public Pages)           • /teams/:team_id (Team Public View)     │
 │   • /current_team (App CRUD)   • /admin (Admin & MissionControl Jobs)   │
 └───────────────────────────────────┬─────────────────────────────────────┘
                                     │
 ┌───────────────────────────────────▼─────────────────────────────────────┐
 │                         Multi-Tenancy & Auth Layer                      │
 │   • Current (user, team, member)   • ActionPolicy (Authorization)       │
 │   • TeamScope & Authentication     • Logins (Session Device Tracking)   │
 └───────────────────────────────────┬─────────────────────────────────────┘
                                     │
 ┌───────────────────────────────────▼─────────────────────────────────────┐
 │                             Data Models                                 │
 │  ┌──────────┐         ┌──────────┐         ┌─────────────────────────┐  │
 │  │   User   │◄───────►│  Member  │◄───────►│          Team           │  │
 │  └──────────┘         └──────────┘         └────────────┬────────────┘  │
 │                                                         │               │
 │                                            ┌────────────▼────────────┐  │
 │                                            │         Memory          │  │
 │                                            └───┬─────┬─────┬─────┬───┘  │
 │                                                │     │     │     │      │
 │                         ┌──────────────────────┘     │     │     └────┐ │
 │                         ▼                            ▼     ▼          ▼ │
 │                   ┌──────────┐                  ┌─────────┐┌─────────┐┌─────────┐
 │                   │ Location │                  │ Picture ││ Thought ││ Weblink │
 │                   └──────────┘                  └─────────┘└─────────┘└─────────┘
 └─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Model Layer Analysis & Context

The model layer sits on top of a custom base hierarchy designed around custom string IDs (**YID**) and content visibility lifecycles.

### Base Classes & Core Framework
* **`ApplicationRecord`**: Root ActiveRecord base class connecting to the primary PostgreSQL database.
* **`ApplicationRecordYidEnabled`**:
  * Abstract base class providing custom ID generation (`#{YID_CODE}_#{iso8601_timestamp}_#{hex6}`), e.g. `loc_2026-08-07T16:00:00.000000Z_a1b2c3`.
  * Overrides `to_param` with Base64 URL-safe encoding (`urlsafe_id`).
  * Implements `fynd`, `urlsafe_find`, `urlsafe_find!`, and `RecordHistoryService` hooks (`create_with_history`, `update_with_history`, `destroy_with_history`).
  * Sets a global `default_scope { order(created_at: :desc) }`.
* **`ApplicationRecordForContentAndPosts`**:
  * Abstract subclass of `ApplicationRecordYidEnabled` for all user-generated content.
  * Defines visibility lifecycle: `VISIBILITY_STATES = %w[draft internal published archived blocked]`.
  * Dynamically defines state inquiry methods (`draft?`, `internal?`, `published?`, `archived?`, `blocked?`).
* **`Current` (`ActiveSupport::CurrentAttributes`)**:
  * Request-scoped global store holding `user`, `team`, `member`, `module_name`, `path`, and `request_id`.

### Identity & Multi-Tenancy Models
* **`User`** (`YID_CODE: "user"`):
  * Manages authentication via `has_secure_password :password, validations: false`.
  * Normalizes `email`, `name`, and `nickname`.
  * Supports system roles: `admin`, `account_manager`, `moderator`, `editor`, `user`.
  * Has many `logins` and `memberships` (`Member`).
* **`Team`** (`YID_CODE: "team"`):
  * The primary tenant entity. Owns all locations, pictures, thoughts, weblinks, memories, and members.
  * Holds JSONB `preferences`. Unique `name` (7..72 chars).
* **`Member`** (`YID_CODE: "member"`):
  * Join model between `User` and `Team`.
  * Stores roles as a PostgreSQL text array column (`roles`), e.g. `owner`, `manager`, `editor`, `publisher`.
  * Uses custom `ArrayInclusionValidator` and PostgreSQL array containment scopes (`with_roles`, `without_roles`).
* **`Login`**:
  * Session and device tracker. Hashes `ip_address` + `user_agent` into a unique SHA256 `device_id`.
* **`RecordHistory`**:
  * Append-only audit log table storing `:created`, `:updated`, and `:deleted` events across team entities.

### Content & Journaling Models
* **`Location`** (`YID_CODE: "loc"`):
  * Stores `lat`, `long`, `address`, `country_code`, JSONB `geocoded_address`, and `url`.
  * Integrated with `geocoder` gem + Geoapify for automatic forward & reverse geocoding on address/coordinate changes.
  * Generates static map URLs and Google Maps navigation links.
* **`Picture`** (`YID_CODE: "pic"`):
  * Wraps an `ActiveStorage` attachment (`has_one_attached :file`).
  * Validates dimensions (400px–4000px), file size (150KB–6MB), and content types.
  * Generates WebP variants (`thumbnail`, `preview`, `large`) on demand via `ruby-vips`.
* **`Thought`** (`YID_CODE: "thot"`):
  * Short text snippets / journal notes (1..512 chars).
* **`Weblink`** (`YID_CODE: "link"`):
  * Bookmarks / external URLs with automatic HTTPS normalization.
* **`Memory`** (`YID_CODE: "memo"`):
  * The central "Post" record. Combines a short text memo (4..500 chars) with optional single references to `location`, `picture`, `thought`, and `weblink`.
  * Synchronizes visibility states across attached items on save.

---

## 3. Controller Layer Analysis & Context

The controller layer is structured cleanly across 3 distinct namespaces with heavy concern reuse:

```
app/controllers/
├── application_controller.rb (Base)
├── concerns/
│   ├── authentication.rb      (Session management, sign_in, sign_out)
│   ├── team_scope.rb          (Current team & member resolution, switching)
│   ├── request_context.rb     (Current object assignments)
│   └── logins.rb             (Device session tracking & pruning)
├── current_teams/             (App namespace: /current_team/*)
├── teams/                     (Public namespace: /teams/:team_id/*)
└── admins/                    (Admin namespace: /admin/*)
```

### Core Base & Concerns
* **`ApplicationController`**:
  * Enforces `verify_authorized` via **ActionPolicy**.
  * Wires `authorize :user`, `authorize :team`, `authorize :member`.
  * Integrates `ErrorHandler` for friendly error pages in production.
  * Provides `validate_params!` and `validate_params_for!` leveraging **Dry-Validation** contracts.
* **`Concerns::Authentication`**: Manages `session[:user_id]`, `current_user`, and authentication redirects.
* **`Concerns::TeamScope`**: Manages `session[:team_id]`, `current_team`, `current_member`, team switching, and fallback to user's first team.
* **`Concerns::RequestContext`**: Populates `Current.user`, `Current.team`, `Current.member`, `Current.module_name`, `Current.path`.

### Namespaces & Endpoints
1. **`CurrentTeams::` Controllers (`/current_team/...`)**:
   * Internal application CRUD actions scoped to `Current.team`.
   * Includes `LocationsController`, `PicturesController`, `ThoughtsController`, `WeblinksController`, `MemoriesController`, `MembersController`, `ContentVisibilityController` (bulk visibility transitions), and `SearchesController` (full-text search via `PgSearch`).
2. **`Teams::` Controllers (`/teams/:team_id/...`)**:
   * Read-only public/guest view of published team content.
3. **`Admins::` Controllers (`/admin/...`)**:
   * Global management controllers protected by `AdminConstraint` (requiring `current_user.admin?`).
   * Mounts **MissionControl::Jobs** at `/admin/jobs`.

---

## 4. View Layer & Frontend Architecture

* **Template Engine**:
  * Predominantly written in **Slim** (`.html.slim`), delivering concise, indented HTML structures.
  * Select specs test rendered output with HTML-escaping awareness.
* **Component Architecture (ViewComponent)**:
  * Heavily modularized with 19 reusable `ViewComponent` classes under `app/view_components/`:
    * *Navigation*: `ApplicationNavComponent`, `ApplicationNavLinksComponent`, `AdminNavComponent`, `TeamSwitcherComponent`.
    * *Admin & Audit*: `AdminShowTeamComponent`, `AdminShowRecordHistoryComponent`, `AdminShowRecordEventComponent`.
    * *Data Presentation*: `SearchResultsComponent`, `MapLinkComponent`, `DeviceComponent`, `ExternalLinkComponent`.
* **Hotwire Stack**:
  * **Turbo Rails**: SPA-like navigation, frame rendering, and form responses.
  * **Stimulus JS**: Modest controllers for interactive widgets.
  * **Importmaps**: Zero-build JS asset management via `config/importmap.rb`.

---

## 5. Background Infrastructure & The Solid Stack

The application fully embraces the Rails 8 **Solid Stack**, utilizing SQLite for peripheral workloads while keeping the main transactional data in PostgreSQL:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Database Setup (database.yml)                   │
├──────────────────────────┬─────────────────────────────────────────────┤
│ Primary Database         │ PostgreSQL (Locations, Pictures, Users, etc)│
├──────────────────────────┼─────────────────────────────────────────────┤
│ SolidCache               │ SQLite (storage/*_cache.sqlite3)            │
├──────────────────────────┼─────────────────────────────────────────────┤
│ SolidCable               │ SQLite (storage/*_cable.sqlite3)            │
├──────────────────────────┼─────────────────────────────────────────────┤
│ SolidQueue               │ SQLite (storage/*_queue.sqlite3)            │
└──────────────────────────┴─────────────────────────────────────────────┘
```

* **SolidQueue**:
  * Manages active background tasks, recurring executions, and retries.
  * Recurring jobs configured (e.g. `CleanupArchivedRecordsJob`).
  * Monitoring dashboard provided by **Mission Control: Jobs** mounted at `/admin/jobs`.
* **SolidCache**:
  * Backs `Rails.cache` with SQLite storage, avoiding Redis overhead.
* **SolidCable**:
  * Backs ActionCable websockets via SQLite database tables.

---

## 6. What Works Already (Static Code Analysis & Test Status)

1. **Comprehensive Test Suite**:
   * **258 RSpec examples passing with 0 failures**.
   * RuboCop clean (0 offenses across 198 files).
   * Active Record Doctor clean (0 orphaned foreign keys, 0 missing indexes).
   * FactoryBot linter clean across all factories and traits.
2. **Multi-Tenant Team Scoping**:
   * Full isolation of content by `team_id`.
   * Seamless switching between teams via `SwitchCurrentTeamsController`.
3. **Rich Content CRUD**:
   * Creation, validation, editing, and deletion of Locations, Pictures, Thoughts, Weblinks, and Memories.
4. **Geocoding & Static Maps**:
   * Integration with Geoapify via `geocoder` gem, automatically calculating coordinates from addresses and vice versa.
5. **Image Processing Pipeline**:
   * File type, dimension, and byte size validations.
   * On-demand WebP variant generation (`thumbnail`, `preview`, `large`) via `ruby-vips`.
6. **Authorization & Security**:
   * ActionPolicy policy enforcement across every controller action.
   * Device session tracking with SHA256 hashed device IDs.
7. **Full-Text Multisearch**:
   * Unified search across locations, pictures, thoughts, weblinks, and members via `pg_search`.
8. **Audit Trail**:
   * `RecordHistoryService` logging created, updated, and deleted events for team records.

---

## 7. Top 5 Missing Elements

Based on the repository state and project vision (`TODO.markdown` / `MAPS_TODO.markdown` / `CROSSPOSTINGS.markdown`):

1. **Interactive Frontend Map & Route Visualization**:
   * While `Location` has coordinates, address geocoding, and static map URLs, there is no client-side interactive map engine (MapLibre GL / Protomaps / Leaflet) or route polyline rendering connecting stops.
2. **Journey / Chronicle / Day Composition Entity**:
   * `Memory` binds single instances of thought/photo/location/link together, but there is no higher-level `Journey`, `Trip`, `Day`, or `Chronicle` model to group memories into a cohesive narrative sequence.
3. **Public Journal / Reader Experience**:
   * The public-facing views under `/teams/:team_id` are minimal stubs; there is no styled reader view, timeline feed, or public travel blog layout for guests.
4. **Social Sharing & Crossposting Engine**:
   * As detailed in `CROSSPOSTINGS.markdown`, there are no automated background dispatchers for Bluesky, Mastodon, X, or rich OpenGraph share card generators.
5. **User Registration, Onboarding & Team Invitations**:
   * The app supports logging in and switching teams, but lacks public self-service registration (creating a user + initial team), email verification, password reset, and member invitation tokens.

---

## 8. Architectural Choices & Technical Quirks (Critical Assessment)

*Note: This section assesses intentional design decisions and unconventional patterns in the codebase.*

### 1. Custom YID (`ApplicationRecordYidEnabled`) vs Standard UUID / Bigint
* **The Pattern**: Primary keys are custom strings (`loc_2026-08-07T16:00:00.000000Z_hex6`) encoded to Base64 in URLs (`urlsafe_id`), with custom finder methods (`fynd`, `urlsafe_find`).
* **Pros**: Instantly identifies model type from ID (`loc_...`, `pic_...`), embeds timestamp for sorting, obfuscates sequential database IDs in URLs.
* **Tradeoffs / Quirks**:
  * Overrides standard Rails `to_param` behavior.
  * Relies on class variables (`@@descendants`, `@@id_code_models`) and an eager loading hack (`Rails.application.eager_load!`) to map prefixes to model classes.
  * Larger index and foreign key storage footprint in PostgreSQL compared to 8-byte `bigint` or native 16-byte `uuid`.

### 2. Global `default_scope { order(created_at: :desc) }`
* **The Pattern**: Placed in `ApplicationRecordYidEnabled`, affecting all content models.
* **Pros**: Newest records automatically show up first in feeds without repeating `.order(created_at: :desc)`.
* **Tradeoffs / Quirks**:
  * Widely recognized Rails anti-pattern. Can cause subtle bugs in subqueries, pagination, batch processing (`find_in_batches` ignores default order), and query optimization unless explicitly overridden with `.reorder(nil)` / `.unscope(:order)`.

### 3. Multi-Database Architecture (Postgres + 3 SQLite databases)
* **The Pattern**: Primary transactional data lives in PostgreSQL, while SolidCache, SolidCable, and SolidQueue each use dedicated SQLite files in `storage/`.
* **Pros**: Excellent for lightweight single-server deployments (e.g. Kamal VPS), avoids PostgreSQL connection pool exhaustion and table bloat from high-frequency job/cache writes.
* **Tradeoffs / Quirks**:
  * In a multi-server or container-replicated environment, SQLite files are ephemeral unless mounted on shared network volumes (NFS/EFS), which can introduce file-locking latency. For horizontal scaling, moving queue/cache back to Postgres or dedicated services is necessary.

### 4. Dynamic Method Definition via `after_initialize` Metaprogramming
* **The Pattern**: In `ApplicationRecordForContentAndPosts` and `Member`, methods like `draft?`, `published?`, `owner?`, `manager?` are dynamically attached via `self.class.send(:define_method, ...)` on `after_initialize`.
* **Pros**: Automatic query helpers for role and visibility checks.
* **Tradeoffs / Quirks**:
  * Incurring metaprogramming overhead on every model instantiation (`after_initialize`). Standard Rails `enum` or explicit class-level method definitions are significantly faster and cleaner.

### 5. Dual Validation Architecture (ActiveRecord Validations + Dry-Validation Contracts)
* **The Pattern**: Controllers utilize `validate_params!` with `dry-validation` contracts, while models also maintain standard ActiveRecord validations (`validates :name`, `validates :roles`).
* **Pros**: Strict boundary validation for incoming HTTP/JSON payloads before hitting models.
* **Tradeoffs / Quirks**:
  * Duplicate validation logic across contracts and models. Requires maintaining both layers in sync.

### 6. View Layer Mix (Slim Templates + ViewComponent + ERB)
* **The Pattern**: Slim is used for views, ViewComponents for modular UI cards, and standard ERB in select view specs.
* **Pros**: Clean, indentation-based syntax in views; clean component separation.
* **Tradeoffs / Quirks**:
  * Less common in standard Rails 8 ecosystems where ERB + Hotwire is default. Requires explicit HTML escaping care (`CGI.escapeHTML`) in tests when testing rendered HTML fragments.
