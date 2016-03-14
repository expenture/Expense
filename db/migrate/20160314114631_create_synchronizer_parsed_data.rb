class CreateSynchronizerParsedData < ActiveRecord::Migration[5.0]
  def change
    create_table :synchronizer_parsed_data do |t|
      t.integer :collected_page_id
      t.string :synchronizer_uid, null: false
      t.string :transaction_uid
      t.string :account_uid
      t.string :attribute_1
      t.string :attribute_2
      t.text :raw_data
      t.datetime :organized_at

      t.timestamps
    end

    add_index :synchronizer_parsed_data, :collected_page_id
    add_index :synchronizer_parsed_data, :synchronizer_uid
    add_index :synchronizer_parsed_data, :transaction_uid
    add_index :synchronizer_parsed_data, :account_uid
    add_index :synchronizer_parsed_data, :organized_at
  end
end
