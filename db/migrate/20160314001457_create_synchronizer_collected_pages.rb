class CreateSynchronizerCollectedPages < ActiveRecord::Migration[5.0]
  def change
    create_table :synchronizer_collected_pages do |t|
      t.string :synchronizer_uid, null: false
      t.string :attribute_1
      t.string :attribute_2
      t.text :header
      t.text :body
      t.datetime :parsed_at
      t.datetime :skipped_at

      t.timestamps
    end

    add_index :synchronizer_collected_pages, :synchronizer_uid
    add_index :synchronizer_collected_pages, :parsed_at
    add_index :synchronizer_collected_pages, :skipped_at
  end
end
