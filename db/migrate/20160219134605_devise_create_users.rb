class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name

      ## Database authenticatable
      t.string   :email,              null: false, default: ""
      t.string   :encrypted_password, null: false, default: ""
      t.datetime :password_set_at

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :unconfirmed_email
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## Mobile
      t.string   "mobile"
      t.string   "unconfirmed_mobile"
      t.string   "mobile_confirmation_token"
      t.datetime "mobile_confirmation_sent_at"
      t.integer  "mobile_confirm_tries", default: 0, null: false

      ## Photos
      t.string   "external_profile_picture_url"
      t.string   "external_cover_photo_url"

      ## Social Links
      t.string   "fb_id"
      t.string   "fb_email"
      t.text     "fb_access_token"

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
    add_index :users, :fb_id
    add_index :users, :fb_email
  end
end
