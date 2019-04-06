class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :user
      t.string :rakuten_app_id
      t.string :yahoo_app_id
      t.string :progress

      t.timestamps
    end
  end
end
