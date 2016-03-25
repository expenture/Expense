class AddSeparateRelatedColumnsToTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :separated, :boolean, null: false, default: false
    add_index :transactions, :separated
    add_column :transactions, :separate_transaction_uid, :string
    add_index :transactions, :separate_transaction_uid
  end
end
