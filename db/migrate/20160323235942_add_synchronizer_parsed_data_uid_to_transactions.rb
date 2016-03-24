class AddSynchronizerParsedDataUIDToTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :synchronizer_parsed_data_uid, :string
    add_index :transactions, :synchronizer_parsed_data_uid
  end
end
