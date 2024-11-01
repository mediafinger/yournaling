class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :ahoy_visits, id: :uuid do |t|
      t.string :visit_token
      t.string :visitor_token

      # the rest are recommended but optional
      # simply remove any you don't want

      # user
      # t.references :user, type: :uuid
      t.string :user_yid, null: false

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

    add_index :ahoy_visits, :user_yid
    add_foreign_key :ahoy_visits, :users, column: :user_yid, primary_key: :yid

    # rename existing record_histories table to record events

    rename_table "record_histories", "record_events"

    # make record_events compatible with ahoy_events

    add_column :record_events, :visit_id, :uuid, null: true

    change_column_null :record_events, :team_yid, true
    change_column_null :record_events, :user_yid, true

    rename_column :record_events, :event, :name

    add_column :record_events, :time, :virtual, type: :text, as: "created_at", stored: true
    add_column :record_events, :properties, :jsonb #, default: {}, null: false

    add_index :record_events, :visit_id
    add_index :record_events, %i[name time]
    add_index :record_events, :properties, using: :gin, opclass: :jsonb_path_ops

    # add_foreign_key :record_events, :ahoy_visits, column: :visit_id, primary_key: :id
    # add_foreign_key :record_events, :teams, column: :team_yid, primary_key: :yid
    # add_foreign_key :record_events, :users, column: :user_yid, primary_key: :yid

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
