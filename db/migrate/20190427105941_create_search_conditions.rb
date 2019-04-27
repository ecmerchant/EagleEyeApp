class CreateSearchConditions < ActiveRecord::Migration[5.2]
  def change
    create_table :search_conditions do |t|
      t.string :user
      t.string :shop_id
      t.text :keyword
      t.string :category_id
      t.string :store_id
      t.integer :min_price
      t.integer :max_price

      t.timestamps
    end
  end
end
