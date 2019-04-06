class AddSelectedShopToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :selected_shop_id, :string
    add_column :accounts, :search_start, :datetime
    add_column :accounts, :last_keyword, :text
    add_column :accounts, :last_category_id, :string
    add_column :accounts, :last_store_id, :string
  end
end
