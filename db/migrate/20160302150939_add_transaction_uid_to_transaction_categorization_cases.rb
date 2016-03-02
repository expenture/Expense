class AddTransactionUIDToTransactionCategorizationCases < ActiveRecord::Migration[5.0]
  def change
    add_column :transaction_categorization_cases, :transaction_uid, :string
    add_index :transaction_categorization_cases, :transaction_uid
  end
end
