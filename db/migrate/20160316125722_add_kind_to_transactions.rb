class AddKindToTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :kind, :string
    add_index :transactions, :kind
  end
end
