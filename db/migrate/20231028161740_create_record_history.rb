class CreateRecordHistory < ActiveRecord::Migration[7.1]
  def change
    create_table :record_histories, id: :uuid do |t|
      t.string :event, null: false
      t.string :record_type, null: false
      t.string :record_id, null: false
      t.references :team, type: :string, null: false, index: false, foreign_key: false
      t.references :user, type: :string, null: false, index: false, foreign_key: false

      t.timestamps
    end

    add_index :record_histories, %i[event record_type user_id]
    add_index :record_histories, %i[event record_type team_id]
    add_index :record_histories, %i[team_id record_type record_id], name: "index_record_histories_by_team_and_record"
  end
end
