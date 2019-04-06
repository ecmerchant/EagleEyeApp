class AddUniquesToLists < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE lists
        ADD CONSTRAINT for_upsert_lists UNIQUE ("user", "product_id", "shop_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE lists
        DROP CONSTRAINT for_upsert_lists;
    SQL
  end
end
