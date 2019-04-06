class AddUniquesToProducts < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE products
        ADD CONSTRAINT for_upsert_products UNIQUE ("product_id", "shop_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE products
        DROP CONSTRAINT for_upsert_products;
    SQL
  end
end
