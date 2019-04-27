class AddSearchIdToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :search_id, :string
  end
end
