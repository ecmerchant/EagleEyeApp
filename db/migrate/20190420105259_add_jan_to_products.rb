class AddJanToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :jan, :string
  end
end
