class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.string :uid, null: false
      t.string :account_uid, null: false
      t.string :kind

      t.integer :amount, null: false
      t.text :description
      t.string :category_code
      t.string :tags
      t.text :note
      t.datetime :datetime, null: false
      t.float :latitude
      t.float :longitude
      t.string :party_type
      t.string :party_code
      t.string :party_name
      t.string :external_image_url

      t.boolean :separated, null: false, default: false
      t.string :separate_transaction_uid

      t.boolean :on_record
      t.string :record_transaction_uid

      t.string :synchronizer_parsed_data_uid

      t.boolean :ignore_in_statistics, null: false, default: false
      t.datetime :manually_edited_at

      t.timestamps
    end

    add_index :transactions, :uid, unique: true
    add_index :transactions, :account_uid
    add_index :transactions, :kind
    add_index :transactions, :category_code
    add_index :transactions, :separated
    add_index :transactions, :separate_transaction_uid
    add_index :transactions, :on_record
    add_index :transactions, :record_transaction_uid
    add_index :transactions, :ignore_in_statistics
    add_index :transactions, :synchronizer_parsed_data_uid
    add_index :transactions, :manually_edited_at

    add_foreign_key :transactions, :accounts, column: :account_uid,
                                              primary_key: :uid,
                                              on_delete: :cascade

    db_adapter = ActiveRecord::Base.configurations[Rails.env]['adapter']
    reversible do |dir|
      dir.up do
        execute <<-EOL.strip_heredoc.sql_format(db_adapter)
          ALTER TABLE transactions
            ADD CONSTRAINT only_virtual_transaction_can_have_separate_transaction_uid CHECK (
              ((`transactions`.`kind` != 'virtual') AND (`transactions`.`separate_transaction_uid` IS NULL)) OR
              ((`transactions`.`kind` = 'virtual') AND (`transactions`.`separate_transaction_uid` IS NOT NULL))
            )
        EOL
        execute <<-EOL.strip_heredoc.sql_format(db_adapter)
          ALTER TABLE transactions
            ADD CONSTRAINT virtual_transaction_can_not_be_seperated CHECK (
              (`transactions`.`kind` != 'virtual') OR
              ((`transactions`.`kind` = 'virtual') AND (`transactions`.`separated` = 'f'))
            )
        EOL
        execute <<-EOL.strip_heredoc.sql_format(db_adapter)
          ALTER TABLE transactions
            ADD CONSTRAINT on_record_type_and_value_match CHECK (
              (`kind` = 'not_on_record' AND `transactions`.`on_record` = 'f') OR
              (`kind` != 'not_on_record' AND `transactions`.`on_record` = 't')
            )
        EOL
      end
      dir.down do
        execute "ALTER TABLE transactions DROP CONSTRAINT only_virtual_transaction_can_have_separate_transaction_uid"
        execute "ALTER TABLE transactions DROP CONSTRAINT virtual_transaction_can_not_be_seperated"
        execute "ALTER TABLE transactions DROP CONSTRAINT on_record_type_and_value_match"
      end
    end if db_adapter != 'sqlite3'
  end
end
