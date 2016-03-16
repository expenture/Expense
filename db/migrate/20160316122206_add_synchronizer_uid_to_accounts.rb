class AddSynchronizerUIDToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :kind, :string
    add_index :accounts, :kind
    add_column :accounts, :synchronizer_uid, :string
    add_index :accounts, :synchronizer_uid
  end
end
