class AddUnrecordedRelatedColumnsToTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :on_record, :boolean
    add_index :transactions, :on_record
    add_column :transactions, :record_transaction_uid, :string
    add_index :transactions, :record_transaction_uid
  end
end
