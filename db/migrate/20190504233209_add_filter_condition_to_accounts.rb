class AddFilterConditionToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :filter_condition, :string
  end
end
