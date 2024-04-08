class CreateBenchmarkTables < ActiveRecord::Migration[7.1]
  def change
    StrongMigrations.disable_check(:add_foreign_key) # as tables are empty
    StrongMigrations.disable_check(:add_column_generated_stored)

    create_table :benchmark_yids, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :benchmark_yids, :teams, column: :team_yid, primary_key: :yid

    # ---

    # TODO: create YID in postgres - maybe as persisted virtual column?!

    # create_table :benchmark_virtual_yids, id: false do |t|
    #   t.datetime "created_at", null: false
    #   # t.virtual :yid, type: :string, as: "bvy_#{created_at}_#{SecureRandom.hex(6)}", stored: true
    #   # t.virtual :yid, type: :string, as: "bvy_#{Time.current.utc.iso8601(6)}_#{SecureRandom.hex(6)}", stored: true
    #   # t.virtual :yid, type: :string, as: "'bvy_' || created_at::text || '_' || gen_random_bytes(6)::text", stored: true
    #   t.string :team_yid, null: false
    #   t.string :name, null: false
    #   t.datetime "updated_at", null: false
    # end

    # # PG::InvalidObjectDefinition: ERROR:  generation expression is not immutable
    # # as created_at or current_timestamp or now() are NOT immutable (they change)
    # # how to generate a timestamp like Time.current.utc.iso8601(6) and make this work?
    # # cast timestamp to text?
    # # Or do we need a trigger function?!

    # add_column :benchmark_virtual_yids, :yid, :virtual, type: :string, as: "'bvy_' || created_at::text || '_' || gen_random_bytes(6)::text", stored: true
    # # add_column :benchmark_virtual_yids, :yid, :virtual, type: :string, as: "bvy_#{Time.current.utc.iso8601(6)}_#{SecureRandom.hex(6)}", stored: true, primary_key: true
    # execute "ALTER TABLE benchmark_virtual_yids ADD PRIMARY KEY (yid);"

    # # full_name  varchar(101) GENERATED ALWAYS AS
    # #                         (CASE WHEN created_at IS NULL THEN 'xxx'
    # #                          ELSE 'bvy_' || created_at || '_ggg' END) STORED

    # add_foreign_key :benchmark_virtual_yids, :teams, column: :team_yid, primary_key: :yid

    # ---

    create_table :benchmark_uuids, id: :uuid do |t|
      t.string :team_yid, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :benchmark_uuids, :teams, column: :team_yid, primary_key: :yid

    # ---

    create_table :benchmark_ids do |t|
      t.string :team_yid, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :benchmark_ids, :teams, column: :team_yid, primary_key: :yid
  end
end
