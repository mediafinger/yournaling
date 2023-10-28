class CreateRecordHistory < ActiveRecord::Migration[7.1]
  def change
    create_table :record_histories, id: :uuid do |t|
      t.string :event, null: false
      t.string :record_type, null: false
      t.string :record_yid, null: false
      t.string :team_yid, null: false
      t.string :user_yid, null: false

      t.timestamps
    end

    add_index :record_histories, %i[event record_type user_yid]
    add_index :record_histories, %i[event record_type team_yid]
    add_index :record_histories, %i[team_yid record_type record_yid], name: "index_record_histories_by_team_and_record"
  end
end
