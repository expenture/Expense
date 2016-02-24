class AddDefaultAccountUidToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :default_account_uid, :string
    add_index :users, :default_account_uid
  end
end
