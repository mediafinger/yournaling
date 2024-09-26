# frozen_string_literal: true

class UpdateGoodJobs < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # NOTE: commented out due to the switch to SolidQueue

    # --- db/migrate/20240318104915_create_good_job_settings.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     unless connection.table_exists?(:good_job_settings)
    #       create_table :good_job_settings, id: :uuid do |t|
    #         t.timestamps
    #         t.text :key
    #         t.jsonb :value
    #         t.index :key, unique: true
    #       end
    #     end
    #   end

    #   dir.down do
    #     if connection.table_exists?(:good_job_settings)
    #       drop_table :good_job_settings, id: :uuid do |t|
    #         t.timestamps
    #         t.text :key
    #         t.jsonb :value
    #         t.index :key, unique: true
    #       end
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104916_create_index_good_jobs_jobs_on_priority_created_at_when_unfinished.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_jobs_on_priority_created_at_when_unfinished)
    #       add_index :good_jobs, %i[priority created_at], order: { priority: "DESC NULLS LAST", created_at: :asc },
    #         where: "finished_at IS NULL", name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished,
    #         algorithm: :concurrently
    #     end
    #   end

    #   dir.down do
    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_jobs_on_priority_created_at_when_unfinished)
    #       remove_index :good_jobs, %i[priority created_at], order: { priority: "DESC NULLS LAST", created_at: :asc },
    #         where: "finished_at IS NULL", name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished,
    #         algorithm: :concurrently
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104917_create_good_job_batches.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     create_or_remove_batch_tables unless connection.table_exists?(:good_job_batches)
    #   end

    #   dir.down do
    #     create_or_remove_batch_tables if connection.table_exists?(:good_job_batches)
    #   end
    # end

    # def create_or_remove_batch_tables
    #   create_table :good_job_batches, id: :uuid do |t|
    #     t.timestamps
    #     t.text :description
    #     t.jsonb :serialized_properties
    #     t.text :on_finish
    #     t.text :on_success
    #     t.text :on_discard
    #     t.text :callback_queue_name
    #     t.integer :callback_priority
    #     t.datetime :enqueued_at
    #     t.datetime :discarded_at
    #     t.datetime :finished_at
    #   end

    #   change_table :good_jobs do |t|
    #     t.uuid :batch_id
    #     t.uuid :batch_callback_id

    #     t.index :batch_id, where: "batch_id IS NOT NULL"
    #     t.index :batch_callback_id, where: "batch_callback_id IS NOT NULL"
    #   end
    # end

    # # --- db/migrate/20240318104918_create_good_job_executions.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     create_or_remove_execution_tables unless connection.table_exists?(:good_job_executions)
    #   end

    #   dir.down do
    #     create_or_remove_execution_tables if connection.table_exists?(:good_job_executions)
    #   end
    # end

    # def create_or_remove_execution_tables
    #   create_table :good_job_executions, id: :uuid do |t|
    #     t.timestamps

    #     t.uuid :active_job_id, null: false
    #     t.text :job_class
    #     t.text :queue_name
    #     t.jsonb :serialized_params
    #     t.datetime :scheduled_at
    #     t.datetime :finished_at
    #     t.text :error

    #     t.index %i[active_job_id created_at], name: :index_good_job_executions_on_active_job_id_and_created_at
    #   end

    #   change_table :good_jobs do |t|
    #     t.boolean :is_discrete
    #     t.integer :executions_count
    #     t.text :job_class
    #   end
    # end

    # # --- db/migrate/20240318104919_create_good_jobs_error_event.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     unless connection.column_exists?(:good_jobs, :error_event)
    #       add_column :good_jobs, :error_event, :integer, limit: 2
    #       add_column :good_job_executions, :error_event, :integer, limit: 2
    #     end
    #   end

    #   dir.down do
    #     if connection.column_exists?(:good_jobs, :error_event)
    #       remove_column :good_jobs, :error_event, :integer, limit: 2
    #       remove_column :good_job_executions, :error_event, :integer, limit: 2
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104920_recreate_good_job_cron_indexes_with_conditional.rb

    # reversible do |dir|
    #   dir.up do
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
    #       add_index :good_jobs, %i[cron_key created_at], where: "(cron_key IS NOT NULL)",
    #         name: :index_good_jobs_on_cron_key_and_created_at_cond, algorithm: :concurrently
    #     end
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
    #       add_index :good_jobs, %i[cron_key cron_at], where: "(cron_key IS NOT NULL)", unique: true,
    #         name: :index_good_jobs_on_cron_key_and_cron_at_cond, algorithm: :concurrently
    #     end

    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
    #       remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at
    #     end
    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
    #       remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at
    #     end
    #   end

    #   dir.down do
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
    #       add_index :good_jobs, %i[cron_key created_at],
    #         name: :index_good_jobs_on_cron_key_and_created_at, algorithm: :concurrently
    #     end
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
    #       add_index :good_jobs, %i[cron_key cron_at], unique: true,
    #         name: :index_good_jobs_on_cron_key_and_cron_at, algorithm: :concurrently
    #     end

    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
    #       remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at_cond
    #     end
    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
    #       remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at_cond
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104921_create_good_job_labels.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     unless connection.column_exists?(:good_jobs, :labels)
    #       add_column :good_jobs, :labels, :text, array: true
    #     end
    #   end

    #   dir.down do
    #     if connection.column_exists?(:good_jobs, :labels)
    #       remove_column :good_jobs, :labels, :text, array: true
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104922_create_good_job_labels_index.rb

    # reversible do |dir|
    #   dir.up do
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_labels)
    #       add_index :good_jobs, :labels, using: :gin, where: "(labels IS NOT NULL)",
    #         name: :index_good_jobs_on_labels, algorithm: :concurrently
    #     end
    #   end

    #   dir.down do
    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_labels)
    #       remove_index :good_jobs, name: :index_good_jobs_on_labels
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104923_remove_good_job_active_id_index.rb

    # reversible do |dir|
    #   dir.up do
    #     if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_active_job_id)
    #       remove_index :good_jobs, name: :index_good_jobs_on_active_job_id
    #     end
    #   end

    #   dir.down do
    #     unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_active_job_id)
    #       add_index :good_jobs, :active_job_id, name: :index_good_jobs_on_active_job_id
    #     end
    #   end
    # end

    # # --- db/migrate/20240318104924_create_index_good_job_jobs_for_candidate_lookup.rb

    # reversible do |dir|
    #   dir.up do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     unless connection.index_name_exists?(:good_jobs, :index_good_job_jobs_for_candidate_lookup)
    #       add_index :good_jobs, %i[priority created_at], order: { priority: "ASC NULLS LAST", created_at: :asc },
    #         where: "finished_at IS NULL", name: :index_good_job_jobs_for_candidate_lookup,
    #         algorithm: :concurrently
    #     end
    #   end

    #   dir.down do
    #     # Ensure this incremental update migration is idempotent
    #     # with monolithic install migration.
    #     if connection.index_name_exists?(:good_jobs, :index_good_job_jobs_for_candidate_lookup)
    #       add_index :good_jobs, %i[priority created_at], order: { priority: "ASC NULLS LAST", created_at: :asc },
    #         where: "finished_at IS NULL", name: :index_good_job_jobs_for_candidate_lookup,
    #         algorithm: :concurrently
    #     end
    #   end
    # end
  end
end
