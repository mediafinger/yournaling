# frozen_string_literal: true

class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :ahoy_visits, id: :uuid do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :visit_token
      t.string :visitor_token

      # user
      t.references :user, type: :string

      # standard
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain
      t.text :landing_page

      # technology
      t.string :browser
      t.string :os
      t.string :device_type

      # location
      t.string :country
      t.string :region
      t.string :city
      t.float :latitude
      t.float :longitude

      # utm parameters
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_term
      t.string :utm_content
      t.string :utm_campaign

      # native apps
      t.string :app_version
      t.string :os_version
      t.string :platform

      t.datetime :started_at
    end

    add_index :ahoy_visits, :visit_token, unique: true
    add_index :ahoy_visits, %i[visitor_token started_at]

    # rename existing record_histories table to record events
    rename_table "record_histories", "record_events"

    # make record_events compatible with ahoy_events
    change_table :record_events, bulk: true do |t|
      t.column :visit_id, :uuid, null: true
      t.column :time, :virtual, type: :datetime, as: "created_at", stored: true
      t.column :properties, :jsonb
    end

    change_column_null :record_events, :team_id, true # rubocop:disable Rails/BulkChangeTable
    change_column_null :record_events, :user_id, true

    rename_column :record_events, :event, :name

    add_index :record_events, :visit_id
    add_index :record_events, %i[name time]
    add_index :record_events, :properties, using: :gin, opclass: :jsonb_path_ops

    # add_foreign_key :record_events, :ahoy_visits, column: :visit_id
    # add_foreign_key :record_events, :teams, column: :team_id
    # add_foreign_key :record_events, :users, column: :user_id

    # create_table :ahoy_events, id: :uuid do |t|
    #   t.references :visit, type: :uuid
    #   t.references :user, type: :uuid
    #   t.string :name
    #   t.jsonb :properties
    #   t.datetime :time
    # end
    #
    # add_index :ahoy_events, %i[name time]
    # add_index :ahoy_events, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
