class AddUniquesToCategory < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE categories
        ADD CONSTRAINT for_upsert_categories UNIQUE ("category_id", "shop_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE categories
        DROP CONSTRAINT for_upsert_categories;
    SQL
  end
end
