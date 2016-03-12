class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.integer :user_id, null: false
      t.string  :uid, null: false
      t.string  :type, default: 'cash', null: false
      t.string  :name, null: false
      t.string  :currency, default: 'TWD', null: false
      t.integer :balance, default: 0, null: false

      t.timestamps
    end

    add_index :accounts, :user_id
    add_index :accounts, :uid, unique: true
    add_index :accounts, :type

    add_foreign_key :accounts, :users, on_delete: :cascade
  end
end
