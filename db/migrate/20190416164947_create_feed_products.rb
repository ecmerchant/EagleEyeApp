class CreateFeedProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :feed_products do |t|
      t.string :group
      t.string :name
      t.string :feed_type

      t.timestamps
    end
  end
end
