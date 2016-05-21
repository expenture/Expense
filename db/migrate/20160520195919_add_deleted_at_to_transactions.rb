class AddDeletedAtToTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :deleted_at, :datetime
    add_index :transactions, :deleted_at
  end
end
