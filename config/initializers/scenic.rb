# frozen_string_literal: true

# This app has 4 databases (1 Postgres primary + 3 SQLite for SolidCable/Cache/Queue,
# see config/database.yml). `db:schema:dump` dumps each database's schema.rb through
# ActiveRecord::Tasks::DatabaseTasks#with_temporary_pool, which isolates a single
# connection pool for the duration of each database's dump. Scenic's SchemaDumper
# patch (`views`) ignores which connection is currently being dumped and always
# queries its own globally-configured (Postgres-only) adapter, so while dumping the
# SQLite schemas it blows up with "no such table: pg_class".
#
# Guarding on the dumper's own current connection (`@connection`, set in
# ActiveRecord::SchemaDumper#initialize) — rather than Scenic's separately configured
# adapter — only ever attempts the Postgres view query while Postgres is actually the
# database being dumped.
Rails.application.config.to_prepare do
  Scenic::SchemaDumper.prepend(Module.new do
    def views(stream)
      super if @connection.adapter_name == "PostgreSQL"
    end
  end)
end
