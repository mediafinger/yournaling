# Top 10 Next Steps — Yournaling Roadmap

This document outlines the **Top 10 technical and product milestones** to advance Yournaling from its current functional prototype into a full-featured, elegant travel journaling platform.

> [!NOTE]
> This roadmap focuses purely on **core domain modeling, product features, user experience, and architectural robustness**. Production deployment, DevOps provisioning, and hosting operations are intentionally excluded.

---

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                           PRODUCT EVOLUTION MAP                         │
 ├────────────────────────────────────┬────────────────────────────────────┤
 │  1. Chronicles & Rich Stories      │  6. Photo EXIF & Auto-Placement    │
 │  2. Interactive Map Engine         │  7. User Registration & Invites    │
 │  3. Journeys & Itineraries         │  8. Automated Social Crossposting  │
 │  4. Public Reader Experience       │  9. Tagging & Faceted Search       │
 │  5. Route Polylines & GPX Tracks   │ 10. Core Architecture Refactoring  │
 └────────────────────────────────────┴────────────────────────────────────┘
```

---

## 1. Chronicles & Rich Stories (Markdown Travel Journal Entries)

* **The Goal**:
  Introduce a `Chronicle` (or `Story`) model that allows users to write comprehensive travel articles featuring headlines, dates, rich markdown body text (using Redcarpet/Rouge/EasyMDE), tags, and multi-photo/multi-location associations.
* **The Value it Brings**:
  Unlocks the primary value proposition of Yournaling. While `Memory` handles atomic 500-character snippets, `Chronicle` allows travelers to document full days, meals, hikes, and cultural observations in rich prose.
* **Why it Should Be Worked on Now**:
  Forms the core narrative unit of the application. Subsequent features (timeline views, public reader pages, social cards, journey summaries) all depend on having rich journal articles.
* **Which Next Steps it Enables**:
  - Building multi-day timeline feeds.
  - Grouping chronicles into high-level Journeys and Experiences.
  - Generating rich OpenGraph snippets for social sharing.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Markdown sanitization (preventing XSS while allowing rich formatting and embedded media).
  - Designing clean join tables / associations to attach multiple existing `Picture`, `Location`, and `Weblink` records without duplication.
  - Keeping visibility state transitions in sync across attached child records.

---

## 2. Interactive Map Engine (MapLibre GL + Geoapify Vector Tiles)

* **The Goal**:
  Build a dedicated Stimulus `map_controller.js` and responsive map view components (`MapComponent`) to render interactive vector maps with custom location pins, photo popup cards, and smooth pan/zoom controls.
* **The Value it Brings**:
  Transforms raw GPS coordinates into a visual, interactive travel experience. Users can explore their travels geographically without paying Google Maps API fees.
* **Why it Should Be Worked on Now**:
  `Location` already supports geocoding, reverse-geocoding, and Geoapify API integration in the backend, but the frontend currently only renders static Google Maps links and static image placeholders.
* **Which Next Steps it Enables**:
  - Drawing journey route polylines connecting travel stops.
  - Geographic photo clustering (viewing all photos taken in a specific country/city).
  - Interactive itinerary planning.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Managing WebGL canvas lifecycles and responsive resizing inside Turbo Frame page navigations.
  - Client-side marker clustering performance when a journal contains hundreds of locations and photos.
  - Handling offline tile caching or gracefully failing when network connectivity drops during travel.

---

## 3. Journeys & Experiences Hierarchy (Trip Aggregation & Itineraries)

* **The Goal**:
  Implement `Journey` and `Experience` domain models that group related Chronicles and Memories into multi-day/multi-week itineraries with milestone goals and progress tracking (e.g. *km driven, elevation gain, days sober, van conversion steps*).
* **The Value it Brings**:
  Elevates disconnected daily posts into cohesive, structured adventure logs (e.g. *"3-Week Andalusia Roadtrip 2026"* or *"Camper Van Solar Build"*).
* **Why it Should Be Worked on Now**:
  Establishes the complete domain model hierarchy (`Team` ➔ `Journey` ➔ `Experience` ➔ `Chronicle` ➔ `Memory` ➔ `Insights`) before building the public reading and publishing interfaces.
* **Which Next Steps it Enables**:
  - Chronological Day-by-Day travel navigation (*"Day 1: Arrival" ➔ "Day 2: The Alhambra"*).
  - Overall trip statistics (total distance, duration, countries visited).
  - Full-journey GPX and GeoJSON backup exports.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Complex nested inclusion logic (handling visibility rules when an experience is published but individual memories inside it are drafts).
  - Reordering and sequence management across journey days.
  - Multi-level ActiveRecord eager-loading optimization to prevent N+1 query bottlenecks on large journeys.

---

## 4. Public Journal Reader Experience & Timeline UI

* **The Goal**:
  Design and build a responsive public-facing reading interface under `/teams/:team_id` featuring hero banners, magazine-style timeline feeds, photo lightboxes, and clean typography.
* **The Value it Brings**:
  Delivers the product experience for external readers (friends, family, travel community). A journal that cannot be beautifully consumed by guests fails its core mission.
* **Why it Should Be Worked on Now**:
  Currently, `/teams/:team_id` routes are minimal stubs. Developing the public view validates that content permissions, visibility filters (`published` vs `internal`), and ViewComponents render seamlessly.
* **Which Next Steps it Enables**:
  - Guest engagement (reactions, comments, reader subscriptions).
  - Public SEO optimization and OpenGraph link card previews.
  - Public travel profile landing pages for teams and vans.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Designing a layout that looks stunning with varying photo aspect ratios (landscape, portrait, square).
  - Optimizing initial page load and lazy-loading high-resolution images across mobile connections.
  - Ensuring strict scoping so draft, internal, or blocked records never leak to unauthenticated readers.

---

## 5. Journey Route Polylines & GPX Track Uploads

* **The Goal**:
  Allow users to upload standard `.gpx` GPS tracks or automatically calculate and draw connecting route lines between chronological stops on journey maps.
* **The Value it Brings**:
  Shows readers the exact route taken (hiking trails, cycling tracks, scenic van routes), providing immense visual context beyond isolated pins.
* **Why it Should Be Worked on Now**:
  Directly builds on the Interactive Map Engine (Step 2) and Journey Hierarchy (Step 3), completing the core visual promise described in `TODO.markdown`.
* **Which Next Steps it Enables**:
  - Elevation profile charts and speed/pace metrics along trails.
  - Automatic matching of photos to route coordinates based on timestamps.
  - Interactive "travel along the route" map animations.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Parsing and simplifying large XML GPX files with thousands of track points into lightweight GeoJSON LineStrings.
  - Filtering out GPS noise and stationary jitter points.
  - Storing track geometries efficiently in PostgreSQL.

---

## 6. Photo EXIF Extraction & Automatic Map Placement

* **The Goal**:
  Implement an automated ActiveStorage metadata extraction pipeline that parses EXIF tags (`GPSLatitude`, `GPSLongitude`, `DateTimeOriginal`, `CameraModel`) using `ruby-vips` or `exifr` upon image upload.
* **The Value it Brings**:
  Frictionless authoring: travelers can drop in 10 photos taken during the day, and the system automatically proposes exact GPS coordinates, dates, and locations without manual entry.
* **Why it Should Be Worked on Now**:
  `Picture` already has the `ruby-vips` processing pipeline and dimension validation in place. Adding EXIF extraction connects uploaded photos directly to the `Location` model.
* **Which Next Steps it Enables**:
  - "Photos Near Me" and map clustering features.
  - Auto-generating travel days and chronology based on photo timestamps.
  - Automatic reverse-geocoding of photo locations into readable city/country names.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Privacy safeguards: stripping sensitive GPS data when serving images publicly while retaining coordinates in the application database.
  - Handling smartphone photos with missing, scrubbed, or spoofed EXIF metadata.
  - Time zone conversions when international travelers cross borders during a trip.

---

## 7. User Registration, Onboarding & Team Invitations

* **The Goal**:
  Build the self-service user onboarding flow: account registration, email verification, initial team creation wizard, and secure token-based team invitations (`MemberInvite` model + SolidQueue background mailer).
* **The Value it Brings**:
  Transforms the app from a developer-seeded database into a platform where real users can sign up, create their travel journal, and invite partners or co-travelers to collaborate with distinct roles (`owner`, `editor`, `publisher`, `reader`).
* **Why it Should Be Worked on Now**:
  The authentication foundation (`has_secure_password`, `Current.user`, `Member` roles) is established, but there is no mechanism for anyone to join or create teams without manual Rails console intervention.
* **Which Next Steps it Enables**:
  - Multi-user collaboration on shared journeys.
  - Password reset and account profile management.
  - Role-based publishing workflows (`editor` drafts ➔ `publisher` releases).
* **Difficulties, Complexities & Maintenance Challenges**:
  - Secure invitation token generation, expiration, and replay prevention.
  - Handling invitation acceptance for users who do not yet have an account.
  - Transactional safety: ensuring team creation and default member ownership roll back cleanly if onboarding fails.

---

## 8. Automated Social Crossposting Engine (Bluesky, Mastodon, X)

* **The Goal**:
  Implement the background job dispatchers (SolidQueue) and UI modal designed in `CROSSPOSTINGS.markdown` to automatically generate smart excerpts, resize 1 hero image, and publish updates to Bluesky (AT Protocol), Mastodon (REST), and X (API v2).
* **The Value it Brings**:
  Allows travelers to write once on Yournaling and broadcast attractive teaser cards across all their social channels with one click, driving readers back to their personal journal.
* **Why it Should Be Worked on Now**:
  The technical blueprint and API specs are completely researched and documented in `CROSSPOSTINGS.markdown`. Connecting this to `Memory` / `Chronicle` publishing delivers immediate syndication power.
* **Which Next Steps it Enables**:
  - Audience growth and referral traffic analytics.
  - RSS / Atom feed generation for automated platform syndication.
  - Expandable connector architecture for LinkedIn, Instagram, and messaging deep links.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Encrypting third-party OAuth access tokens and app passwords securely at rest in PostgreSQL (`ActiveRecord::Encryption`).
  - Handling external API rate limits, transient network failures, and token expiration refreshes.
  - Calculating exact UTF-8 byte-range facets for clickable links and hashtags on Bluesky.

---

## 9. Tagging, Filtering & Advanced Full-Text Multisearch

* **The Goal**:
  Expand the existing `pg_search` multisearch integration to support multi-faceted filtering (by tag e.g. `#vanlife #hiking`, country code, date ranges, and content types) with real-time Turbo Frame search updates.
* **The Value it Brings**:
  As travel journals grow over months and years, fast search and tag filtering allow both authors and readers to instantly find specific memories, locations, campsites, and restaurants.
* **Why it Should Be Worked on Now**:
  `multisearchable` is already configured on models, but the UI search experience is basic. Adding tags and country facets completes the discovery loop.
* **Which Next Steps it Enables**:
  - Tag cloud navigation and curated topic feeds.
  - Country-specific travel archives (*"All memories in France"*).
  - Search autocomplete with Stimulus and Turbo Frames.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Maintaining strict multi-tenant isolation so search results never leak private or draft content from other teams.
  - Index performance tuning in PostgreSQL for combined JSONB and full-text search vectors.

---

## 10. Refactoring Core Architectural Quirks (Technical Health)

* **The Goal**:
  Address the technical quirks identified in `ANALYSIS_OF_STATUS_QUO.md`:
  1. Remove global `default_scope { order(created_at: :desc) }` in `ApplicationRecordYidEnabled` in favor of explicit query objects / scopes.
  2. Replace dynamic `after_initialize` metaprogramming in `ApplicationRecordForContentAndPosts` and `Member` with standard Rails `enum` and explicit predicate methods.
* **The Value it Brings**:
  Eliminates subtle bugs in subqueries, pagination, and batch processing; speeds up model instantiation; removes class variable hacks; and aligns the codebase with idiomatic Rails best practices.
* **Why it Should Be Worked on Now**:
  Performing this cleanup while the codebase is in early active development is fast and low-risk. Postponing it until dozens of models and complex queries exist will make refactoring exponentially harder.
* **Which Next Steps it Enables**:
  - Predictable ActiveRecord query chaining and subquery execution.
  - Cleaner integration with future reporting and aggregation queries.
  - Reduced memory footprint during heavy batch operations.
* **Difficulties, Complexities & Maintenance Challenges**:
  - Updating existing controller queries and view specs that implicitly relied on the default descending order.
  - Ensuring backward compatibility with existing tests and fixtures.

---

## Summary Matrix

| # | Milestone | Primary Area | Complexity | Dependencies |
| :-: | :--- | :--- | :-: | :--- |
| **1** | **Chronicles & Stories** | Content Modeling | Medium | `ApplicationRecordForContentAndPosts` |
| **2** | **Interactive Map Engine** | Frontend / Maps | Medium | `Location`, Stimulus, Geoapify |
| **3** | **Journeys & Experiences** | Domain Modeling | High | `Chronicle`, `Memory` |
| **4** | **Public Reader Timeline** | View Layer / UI | Medium | `Chronicle`, ViewComponent |
| **5** | **Route Polylines & GPX** | Geo / Mapping | High | Interactive Map Engine, `Journey` |
| **6** | **Photo EXIF Auto-Placement** | Media Pipeline | Medium | `Picture`, ActiveStorage |
| **7** | **Onboarding & Invitations** | Auth / Multi-Tenancy | Medium | `User`, `Member`, SolidQueue |
| **8** | **Social Crossposting** | Background / APIs | High | `SolidQueue`, OAuth encryption |
| **9** | **Tagging & Multisearch** | Search & Discovery | Medium | `pg_search`, Turbo Frames |
| **10** | **Architectural Refactoring** | Code Quality | Low–Medium | Active Record layer |
