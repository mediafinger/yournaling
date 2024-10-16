class CreatePgSearchDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :pg_search_documents do |t|
      t.text :content, null: false
      t.string :searchable_type, null: false
      t.string :searchable_id, primary_key: :yid, null: false
      t.string :team_yid, null: false

      t.timestamps null: false
    end

    add_index :pg_search_documents, %w[searchable_type searchable_id], name: "index_pg_search_documents_on_searchable"
    add_index :pg_search_documents, %w[team_yid searchable_type], name: "index_pg_search_documents_on_team_yid"

    add_foreign_key :pg_search_documents, :teams, column: :team_yid, primary_key: :yid
  end
end
