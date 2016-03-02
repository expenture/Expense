class CreateTransactionCategorizationCases < ActiveRecord::Migration[5.0]
  def change
    create_table :transaction_categorization_cases do |t|
      t.integer :user_id
      t.string :words
      t.string :category_code

      t.timestamps
    end
    add_index :transaction_categorization_cases, :user_id
    add_index :transaction_categorization_cases, :category_code
  end
end
