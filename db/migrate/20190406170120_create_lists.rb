class CreateLists < ActiveRecord::Migration[5.2]
  def change
    create_table :lists do |t|
      t.string :user
      t.string :shop_id
      t.string :product_id
      t.string :status
      t.integer :price
      t.string :condition

      t.timestamps
    end
  end
end
