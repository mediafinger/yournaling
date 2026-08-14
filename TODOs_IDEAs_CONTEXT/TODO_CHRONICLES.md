# Feature Concept & TDD Plan: Chronicles

> **Status**: Planned Feature  
> **Origin**: Derived from exploratory branch `add-chronicles` (March 2024), redesigned for the **Journey ➔ Experience ➔ Chronicle** domain hierarchy on Rails 8.1 / ViewComponent architecture on `main`.

---

## 1. Core Concept & Domain Vision

### The Content Hierarchy in Yournaling
$$\text{Team} \longrightarrow \text{Journey} \longrightarrow \text{Experience} \longrightarrow \text{Chronicle} \longrightarrow \text{Memory} \longrightarrow \text{Insights}$$

1. **Insights (Atomic Media & Notes)**: `Picture`, `Location`, `Thought`, `Weblink`, `Story`.
2. **Memory (Single Moment)**: Snapshot of a single moment in time linking at most 1 picture, 1 location, 1 thought, 1 link with a short `memo` (4–500 chars).
3. **Chronicle (Multi-Item Narrative / Day / Chapter)**: A curated story arc (e.g. *"Day 3: The Alhambra & Granada Tapas"* or *"Installing the Solar Controller on the Van"*):
   * **Narrative Story (`story`)**: Rich Markdown text (20 to 5,000+ chars) explaining the day, event, or reflection.
   * **Temporal Scope**: `start_date` and optional `end_date` for chronological timeline placement.
   * **Polymorphic Item Stream**: Interleaved, ordered sequence of media items, embedded atomic memories, locations, pictures, thoughts, and links.
4. **Experience (Multi-Day Adventure / Thematic Project)**: Aggregates multiple Chronicles, Memories, and Insights (e.g. *"Hiking the GR20"* or *"Camper Van Build"*), tracking goals and progress milestones.
5. **Journey (Overall Trip / Vacation / Year in Review)**: High-level container wrapping Experiences and standalone Chronicles (e.g. *"3-Week Andalusia Roadtrip 2026"*).

---

## 2. Database Schema Design (Polymorphic Composition)

`Chronicle` uses a **polymorphic composition model (`chronicle_items`) with unified position ordering** managed by the [`positioning`](https://github.com/brendon/positioning) gem:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_chronicles.rb
class CreateChronicles < ActiveRecord::Migration[8.1]
  def change
    create_table :chronicles, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.string :name, null: false
      t.text :story, null: false # Markdown narrative introduction / notes
      t.date :start_date, null: false
      t.date :end_date
      t.enum :visibility, enum_type: :content_visibility, default: "internal", null: false

      t.timestamps
    end

    add_index :chronicles, [:team_id, :name], unique: true
    add_index :chronicles, [:team_id, :start_date]

    # Polymorphic, ordered item attachment
    create_table :chronicle_items, id: :string do |t|
      t.references :team, null: false, foreign_key: true, type: :string
      t.references :chronicle, null: false, foreign_key: true, type: :string
      t.string :item_type, null: false # "Memory", "Picture", "Location", "Thought", "Weblink"
      t.string :item_id, null: false   # YID string foreign key
      t.integer :position, null: false, default: 1

      t.timestamps
    end

    add_index :chronicle_items, [:chronicle_id, :item_id], unique: true
    add_index :chronicle_items, [:chronicle_id, :position], unique: true
  end
end
```

---

## 3. Ordering Architecture: The `positioning` Gem

Item ordering within a `Chronicle` is managed by [`gem "positioning"`](https://github.com/brendon/positioning) (by Brendon Muir, creator/longtime maintainer of `acts_as_list`).

### 3.1 Why `positioning` was Chosen

1. **Normalized 3NF Data Model**: Each item row owns its position. Standard `ORDER BY position ASC` index scans are $O(1)$ at the database level with a unique compound index (`[:chronicle_id, :position]`).
2. **Gapless 1-Based Sequential Ordering**: Automatically guarantees gapless, sequential integer positions ($1, 2, 3 \dots$) without negative numbers, zero, or duplicate position collisions.
3. **Full Referential Integrity**: Cascades and foreign keys (`dependent: :destroy`) automatically clean up entries and decrement downstream positions. Zero orphaned array references.
4. **Intuitive Relative Placement**:
   ```ruby
   chronicle_item.move_above(other_item)
   chronicle_item.move_below(other_item)
   chronicle_item.move_to_top
   chronicle_item.move_to_bottom
   ```
5. **Direct Blueprint for `Experience` and `Journey`**: Exactly the same gem and declarative DSL applies to `experience_items` (`positioned on: :experience_id`) and `journey_items` (`positioned on: :journey_id`).

---

## 4. Architecture on `main`

### 4.1 Model Layer

```ruby
# app/models/chronicle.rb
class Chronicle < ApplicationRecordYidEnabled
  YID_CODE = "cron"

  belongs_to :team, inverse_of: :chronicles

  has_many :chronicle_items, -> { order(position: :asc) }, inverse_of: :chronicle, dependent: :destroy

  # Polymorphic through associations
  has_many :memories, through: :chronicle_items, source: :item, source_type: "Memory"
  has_many :pictures, through: :chronicle_items, source: :item, source_type: "Picture"
  has_many :locations, through: :chronicle_items, source: :item, source_type: "Location"
  has_many :thoughts, through: :chronicle_items, source: :item, source_type: "Thought"
  has_many :weblinks, through: :chronicle_items, source: :item, source_type: "Weblink"

  accepts_nested_attributes_for :chronicle_items, allow_destroy: true

  multisearchable against: %i[name story]

  normalizes :name, with: ->(name) { name.strip }
  normalizes :story, with: ->(story) { story.strip }

  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :story, presence: true, length: { minimum: 20, maximum: 10_000 }
  validates :start_date, presence: true
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
  validate :validate_date_range

  private

  def validate_date_range
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
```

```ruby
# app/models/chronicle_item.rb
class ChronicleItem < ApplicationRecordYidEnabled
  YID_CODE = "crit"

  belongs_to :team, inverse_of: false
  belongs_to :chronicle, inverse_of: :chronicle_items
  belongs_to :item, polymorphic: true

  positioned on: :chronicle_id

  validates :item_type, presence: true, inclusion: { in: %w[Memory Picture Location Thought Weblink] }
  validates :item_id, presence: true, uniqueness: { scope: :chronicle_id }
  validates :position, presence: true, numericality: { greater_than: 0, only_integer: true }
end
```

### 4.2 Workspace Mode (`current_team_area.html.slim`, `pico.green.css`)
* **Controller**: `CurrentTeams::ChroniclesController < AppCurrentTeamController`
  * Full CRUD (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`).
  * Emits event tracking via `RecordEventService` (`:created`, `:updated`, `:deleted`).
* **Views / Components**:
  * `app/views/current_teams/chronicles/index.html.slim`: Chronological card feed with dates, cover preview, and attached item badges.
  * `app/views/current_teams/chronicles/show.html.slim`: Reader layout with formatted Markdown story and ordered media stream.
  * `app/views/current_teams/chronicles/_form.html.slim`: Markdown editor + item picker / reordering toolbar for attaching existing memories, photos, locations, thoughts, and weblinks.

### 4.3 Browse Mode (`application.html.slim`, `pico.amber.css`)
* **Controller**: `Teams::ChroniclesController < ApplicationController`
  * Public show & index actions respecting `visibility: "published"`.
  * Renders public interactive map with all attached locations, full-resolution picture gallery, and story text.

### 4.4 Admin Mode (`admin_area.html.slim`, `pico.blue.css`)
* **Controller**: `Admins::ChroniclesController < AdminController`
  * System-wide overview, content moderation, and audit history.

---

## 5. TDD Implementation Plan

### Step 1: Dependencies & Model Layer (TDD)
1. **Gemfile**:
   * Add `gem "positioning", "~> 0.7"` to `Gemfile` and run `bundle install`.
2. **Specs First**:
   * Create `spec/factories/chronicles.rb` and `spec/factories/chronicle_items.rb`.
   * Create `spec/models/chronicle_spec.rb`:
     * YID generation (`cron_...`).
     * Team scoping & validation of name, story, dates, and visibility.
     * Polymorphic item associations (`chronicle.pictures`, `chronicle.memories`, etc.).
     * Multi-search indexing (`PgSearch::Document`).
     * Cascade deletion of `chronicle_items` when a chronicle is destroyed.
   * Create `spec/models/chronicle_item_spec.rb`:
     * YID generation (`crit_...`).
     * Position ordering, strictly positive integer validation (`position > 0`), uniqueness within `chronicle_id` (`item_id` and `position`), and relative moves via `positioning` gem.
3. **Implementation**:
   * Create migration `db/migrate/YYYYMMDDHHMMSS_create_chronicles.rb`.
   * Run `bin/rails db:migrate RAILS_ENV=test && bin/rails db:migrate RAILS_ENV=development`.
   * Implement `Chronicle` and `ChronicleItem` models.
   * Verify with `bundle exec rspec spec/models/chronicle_spec.rb spec/models/chronicle_item_spec.rb`.

### Step 2: Workspace CRUD Controller & Views (TDD)
1. **Specs First**:
   * Write `spec/requests/current_teams/chronicles_request_spec.rb`:
     * `GET #index`: lists team's chronicles.
     * `GET #show`: displays story and ordered items.
     * `POST #create`: creates chronicle and logs `RecordEvent` (`name: :created`).
     * `PATCH #update`: updates story and reorders items.
     * `DELETE #destroy`: removes chronicle and logs `RecordEvent` (`name: :deleted`).
     * Multi-tenant security (blocks access to chronicles from other teams).
2. **Implementation**:
   * Add routes under `namespace :current_team`.
   * Create `app/controllers/current_teams/chronicles_controller.rb`.
   * Build Slim templates in `app/views/current_teams/chronicles/`.
   * Verify with `bundle exec rspec spec/requests/current_teams/chronicles_request_spec.rb`.

### Step 3: Public Browse Mode & Visibility (TDD)
1. **Specs First**:
   * Write `spec/requests/teams/chronicles_request_spec.rb`:
     * Guest access to published chronicles.
     * Blocks guest access to `internal` or `draft` chronicles (returns 404).
2. **Implementation**:
   * Add routes under `resources :teams, module: :teams`.
   * Create `app/controllers/teams/chronicles_controller.rb`.
   * Build public Slim templates in `app/views/teams/chronicles/`.
   * Verify with `bundle exec rspec spec/requests/teams/chronicles_request_spec.rb`.

### Step 4: Navigation, Search & View Components
1. **Search Integration**:
   * Update search presenter to format `Chronicle` search results.
   * Update `spec/view_components/search_results_component_spec.rb`.
2. **Navigation Updates**:
   * Add **Chronicles** link to `CurrentTeamNavComponent`.
   * Add **+ Chronicle** button to `ApplicationNavActionsComponent`.
   * Add **Chronicles** resource to `AdminNavComponent`.
   * Update all navigation component specs.

### Step 5: Full Verification & Quality Gate
* Run the complete CI suite:
  ```bash
  source /opt/homebrew/share/chruby/chruby.sh && chruby 4.0.5 && bundle exec rake ci
  ```
