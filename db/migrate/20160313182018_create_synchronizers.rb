class CreateSynchronizers < ActiveRecord::Migration[5.0]
  def change
    create_table :synchronizers do |t|
      t.integer :user_id, null: false
      t.string :uid, null: false
      t.string :type, null: false
      t.boolean :enabled, null: false, default: true
      t.string :schedule, null: false, default: 'normal'
      t.string :name
      t.string :status, null: false, default: 'new'
      t.string :encrypted_passcode_1
      t.string :encrypted_passcode_2
      t.string :encrypted_passcode_3
      t.string :encrypted_passcode_4
      t.string :passcode_encrypt_salt, null: false
      t.datetime :last_scheduled_at
      t.datetime :last_collected_at
      t.datetime :last_parsed_at
      t.datetime :last_synced_at
      t.datetime :last_errored_at

      t.timestamps
    end

    add_index :synchronizers, :user_id
    add_index :synchronizers, :uid, unique: true
    add_index :synchronizers, :type
    add_index :synchronizers, :last_synced_at
    add_index :synchronizers, :last_errored_at
    add_index :synchronizers, :schedule

    add_foreign_key :synchronizers, :users
  end
end
