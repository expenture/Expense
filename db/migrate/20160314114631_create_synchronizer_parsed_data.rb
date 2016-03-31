class CreateSynchronizerParsedData < ActiveRecord::Migration[5.0]
  def change
    create_table :synchronizer_parsed_data do |t|
      t.integer :collected_page_id
      t.string :synchronizer_uid, null: false
      t.string :uid, null: false
      t.string :attribute_1
      t.string :attribute_2
      t.text :raw_data
      t.datetime :organized_at
      t.datetime :skipped_at

      t.timestamps
    end

    add_index :synchronizer_parsed_data, :collected_page_id
    add_index :synchronizer_parsed_data, :synchronizer_uid
    add_index :synchronizer_parsed_data, :uid, unique: true
    add_index :synchronizer_parsed_data, :organized_at
    add_index :synchronizer_parsed_data, :skipped_at
  end
end
