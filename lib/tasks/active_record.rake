# dump the readable db/schema.rb even when using the SQL schema format
#
Rake::Task["db:schema:dump"].enhance do
  return unless Rails.env.development?

  File.open(Rails.root.join("db/schema.rb"), "w") do |stream|
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, stream)
  end
end
