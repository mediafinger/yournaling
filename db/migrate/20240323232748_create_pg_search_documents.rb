class CreatePgSearchDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :pg_search_documents do |t|
      t.text :content, null: false
      t.string :searchable_type, null: false
      t.string :searchable_id, null: false
      t.string :team_id, null: false

      t.timestamps null: false
    end

    add_index :pg_search_documents, %w[searchable_type searchable_id], name: "index_pg_search_documents_on_searchable"
    add_index :pg_search_documents, %w[team_id searchable_type], name: "index_pg_search_documents_on_team_id"

    add_foreign_key :pg_search_documents, :teams, column: :team_id
  end
end
