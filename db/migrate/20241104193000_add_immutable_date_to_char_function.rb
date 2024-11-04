class AddImmutableDateToCharFunction < ActiveRecord::Migration[8.0]
  def up
    # create immutable TO_CHAR(timestamp) function
    #
    execute <<~SQL
      CREATE FUNCTION date_to_text(timestamp) RETURNS text AS
      $$ select to_char($1, 'YYYY-MM-DD'); $$
      LANGUAGE sql immutable;
    SQL
  end

  def down
    execute <<~DROPSQL
      DROP FUNCTION date_to_text(timestamp);
    DROPSQL
  end
end
