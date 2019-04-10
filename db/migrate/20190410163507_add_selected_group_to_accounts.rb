class AddSelectedGroupToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :selected_group, :string
  end
end
