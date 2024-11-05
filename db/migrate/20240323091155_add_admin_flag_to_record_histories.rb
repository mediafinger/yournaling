class AddAdminFlagToRecordHistories < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :record_histories, :done_by_admin, :boolean, default: false, null: false

    add_index :record_histories, %i[done_by_admin user_id record_type], algorithm: :concurrently
  end
end
