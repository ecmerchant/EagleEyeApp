class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :product_id
      t.string :shop_id
      t.text :title
      t.integer :price
      t.string :image1
      t.string :image2
      t.string :image3
      t.string :brand
      t.string :part_number
      t.text :description
      t.string :category_id

      t.timestamps
    end
  end
end
