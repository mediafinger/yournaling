# Feature Concept & TDD Plan: Chronicles

> **Status**: Planned Feature  
> **Origin**: Derived from exploratory branch `add-chronicles` (March 2024), modernized for Rails 8.1 / ViewComponent architecture on `main`.

---

## 1. Core Concept & Domain Vision

### What is a Chronicle?
In Yournaling, a **Memory** is an atomic, single point-in-time journal entry (linking at most 1 picture, 1 location, 1 thought, and 1 link).

A **Chronicle** is a **multi-item narrative chapter or story arc**. It bridges the gap between atomic notes and full pages, allowing users to bundle multiple insights into a curated sequence:
* **Rich Markdown Narrative (`notes`)**: Long-form storytelling (20 to 5,000+ characters) explaining a journey, trip, event, or thematic reflection.
* **Many-to-Many Curated Content**: Embeds multiple **Pictures**, **Locations**, **Thoughts**, and **Weblinks**.
* **Preserved Narrative Order**: Uses PostgreSQL string arrays (`locations_order`, `pictures_order`, `weblinks_order`) to preserve the author's intended sequence rather than arbitrary database IDs.
* **Team & Workspace Scoping**: Seamlessly integrated into both the **Current Team Workspace** (creation/editing in `pico.green.css`) and **Browse Mode** (`pico.amber.css`).

---

## 2. Database Schema Design (Modernized)

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_chronicles.rb
class CreateChronicles < ActiveRecord::Migration[8.1]
  def change
    create_table :chronicles, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.string :name, null: false
      t.text :notes, null: false
      t.string :locations_order, array: true, null: false, default: []
      t.string :pictures_order, array: true, null: false, default: []
      t.string :weblinks_order, array: true, null: false, default: []
      t.string :thoughts_order, array: true, null: false, default: []
      t.enum :visibility, enum_type: :content_visibility, default: "internal", null: false

      t.timestamps
    end

    add_index :chronicles, [:team_id, :name], unique: true

    create_table :chronicle_locations, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.references :chronicle, null: false, foreign_key: true, type: :string
      t.references :location, null: false, foreign_key: true, type: :string
      t.timestamps
    end
    add_index :chronicle_locations, [:chronicle_id, :location_id], unique: true

    create_table :chronicle_pictures, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.references :chronicle, null: false, foreign_key: true, type: :string
      t.references :picture, null: false, foreign_key: true, type: :string
      t.timestamps
    end
    add_index :chronicle_pictures, [:chronicle_id, :picture_id], unique: true

    create_table :chronicle_weblinks, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.references :chronicle, null: false, foreign_key: true, type: :string
      t.references :weblink, null: false, foreign_key: true, type: :string
      t.timestamps
    end
    add_index :chronicle_weblinks, [:chronicle_id, :weblink_id], unique: true

    create_table :chronicle_thoughts, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.references :chronicle, null: false, foreign_key: true, type: :string
      t.references :thought, null: false, foreign_key: true, type: :string
      t.timestamps
    end
    add_index :chronicle_thoughts, [:chronicle_id, :thought_id], unique: true
  end
end
```

---

## 3. Architecture on `main`

### 3.1 Model Layer
* **`Chronicle < ApplicationRecordYidEnabled`**:
  * `YID_CODE = "cron"`
  * `belongs_to :team`
  * Join associations (`has_many :chronicle_pictures`, etc.) and through associations (`has_many :pictures`, etc.).
  * `accepts_nested_attributes_for` with `allow_destroy: true`.
  * `multisearchable against: [:name, :notes]` for full-text search across teams.
  * Validation hooks ensuring order array columns stay synchronized with attached join records.

### 3.2 UI & Navigation Integration
1. **Current Team Workspace (`CurrentTeamNavComponent`, `pico.green.css`)**:
   * Add **Chronicles** link to workspace toolbar.
   * Add "+ Chronicle" to quick creation actions (`ApplicationNavActionsComponent`).
2. **Browse Mode (`Teams::ChroniclesController`, `pico.amber.css`)**:
   * Public chronicle story view displaying formatted markdown, picture carousel/grid, map of linked locations, and linked references.
3. **Admin Area (`Admins::ChroniclesController`, `pico.blue.css`)**:
   * Manage all chronicles system-wide, inspect audit history, and moderate content visibility.

---

## 4. TDD Implementation Plan

### Phase 1: Migration & Models (TDD)
1. **Factories & Model Specs**:
   * Create `spec/factories/chronicles.rb`, `spec/factories/chronicle_locations.rb`, etc.
   * Write `spec/models/chronicle_spec.rb`:
     * YID generation (`cron_...`).
     * Team scoping & validations (name presence/uniqueness per team, notes length).
     * Order preservation logic (`ensure_*_order_complete`).
     * Cascade deletion of join records on chronicle destruction.
     * `multisearchable` document indexing.
2. **Implementation**:
   * Generate migration and run `bundle exec rails db:migrate`.
   * Implement `app/models/chronicle.rb` and join models (`ChroniclePicture`, `ChronicleLocation`, `ChronicleWeblink`, `ChronicleThought`).

### Phase 2: Workspace CRUD Controller & Views
1. **Controller Specs**:
   * Write `spec/requests/current_teams/chronicles_request_spec.rb`:
     * Index, Show, New, Create, Edit, Update, Destroy.
     * Multi-tenant security (ensures users cannot view or edit chronicles from teams they don't belong to).
     * Event tracking verification (`RecordEvent.where(name: :created, record_type: "Chronicle")`).
2. **Implementation**:
   * Create `app/controllers/current_teams/chronicles_controller.rb` inheriting from `AppCurrentTeamController`.
   * Build Slim views / ViewComponents:
     * `app/views/current_teams/chronicles/index.html.slim`
     * `app/views/current_teams/chronicles/show.html.slim`
     * `app/views/current_teams/chronicles/_form.html.slim`

### Phase 3: Public / Team Browse Mode
1. **Request Specs**:
   * Write `spec/requests/teams/chronicles_request_spec.rb`:
     * Public visibility rules (`internal` vs `published`).
2. **Implementation**:
   * Add `app/controllers/teams/chronicles_controller.rb`.
   * Create read-only Slim templates for team visitors.

### Phase 4: Navigation, Search & Admin
1. **Search Integration**:
   * Add `Chronicle` rendering helper to `SearchPresenterComponent` / search results view.
2. **Navigation Updates**:
   * Add `Chronicles` link to `CurrentTeamNavComponent` and `AdminNavComponent`.
   * Update component specs.

### Phase 5: Verification & Quality Gate
* Run full validation suite:
  ```bash
  source /opt/homebrew/share/chruby/chruby.sh && chruby 4.0.5 && bundle exec rake ci
  ```
