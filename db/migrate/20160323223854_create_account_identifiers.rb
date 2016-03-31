class CreateAccountIdentifiers < ActiveRecord::Migration[5.0]
  def change
    create_table :account_identifiers do |t|
      t.integer :user_id, null: false
      t.string :type
      t.string :account_uid
      t.string :identifier, null: false
      t.text :sample_transaction_description
      t.string :sample_transaction_party_name
      t.integer :sample_transaction_amount
      t.datetime :sample_transaction_datetime

      t.timestamps
    end

    add_index :account_identifiers, :user_id
    add_index :account_identifiers, :type
    add_index :account_identifiers, :account_uid
    add_index :account_identifiers, :identifier

    add_foreign_key :account_identifiers, :users, column: :user_id,
                                                  primary_key: :id,
                                                  on_delete: :cascade
  end
end
