class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.string :uid, null: false
      t.string :account_uid, null: false
      t.integer :amount, null: false
      t.text :description
      t.string :category_code
      t.string :tags
      t.text :note
      t.datetime :datetime, null: false
      t.float :latitude
      t.float :longitude
      t.boolean :ignore_in_statistics, null: false, default: false

      t.timestamps
    end

    add_index :transactions, :uid, unique: true
    add_index :transactions, :account_uid
    add_index :transactions, :category_code
    add_index :transactions, :ignore_in_statistics

    add_foreign_key :transactions, :accounts, column: :account_uid,
                                              primary_key: :uid,
                                              on_delete: :cascade
  end
end
