class AddLastPricesToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :last_min_price, :integer
    add_column :accounts, :last_max_price, :integer
  end
end
