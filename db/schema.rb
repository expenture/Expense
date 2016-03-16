# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160316125722) do

  create_table "accounts", force: :cascade do |t|
    t.integer  "user_id",                           null: false
    t.string   "uid",                               null: false
    t.string   "type",             default: "cash", null: false
    t.string   "name",                              null: false
    t.string   "currency",         default: "TWD",  null: false
    t.integer  "balance",          default: 0,      null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "kind"
    t.string   "synchronizer_uid"
    t.index ["kind"], name: "index_accounts_on_kind"
    t.index ["synchronizer_uid"], name: "index_accounts_on_synchronizer_uid"
    t.index ["type"], name: "index_accounts_on_type"
    t.index ["uid"], name: "index_accounts_on_uid", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.text     "token",             null: false
    t.text     "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                      null: false
    t.string   "uid",                       null: false
    t.string   "secret",                    null: false
    t.text     "redirect_uri",              null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "synchronizer_collected_pages", force: :cascade do |t|
    t.string   "synchronizer_uid", null: false
    t.string   "attribute_1"
    t.string   "attribute_2"
    t.text     "header"
    t.text     "body"
    t.datetime "parsed_at"
    t.datetime "skipped_at"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["parsed_at"], name: "index_synchronizer_collected_pages_on_parsed_at"
    t.index ["skipped_at"], name: "index_synchronizer_collected_pages_on_skipped_at"
    t.index ["synchronizer_uid"], name: "index_synchronizer_collected_pages_on_synchronizer_uid"
  end

  create_table "synchronizer_parsed_data", force: :cascade do |t|
    t.integer  "collected_page_id"
    t.string   "synchronizer_uid",  null: false
    t.string   "transaction_uid"
    t.string   "account_uid"
    t.string   "attribute_1"
    t.string   "attribute_2"
    t.text     "raw_data"
    t.datetime "organized_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["account_uid"], name: "index_synchronizer_parsed_data_on_account_uid"
    t.index ["collected_page_id"], name: "index_synchronizer_parsed_data_on_collected_page_id"
    t.index ["organized_at"], name: "index_synchronizer_parsed_data_on_organized_at"
    t.index ["synchronizer_uid"], name: "index_synchronizer_parsed_data_on_synchronizer_uid"
    t.index ["transaction_uid"], name: "index_synchronizer_parsed_data_on_transaction_uid"
  end

  create_table "synchronizers", force: :cascade do |t|
    t.integer  "user_id",                               null: false
    t.string   "account_uid"
    t.string   "uid",                                   null: false
    t.string   "type",                                  null: false
    t.boolean  "enabled",               default: true,  null: false
    t.string   "name"
    t.string   "status",                default: "new", null: false
    t.string   "encrypted_passcode_1"
    t.string   "encrypted_passcode_2"
    t.string   "encrypted_passcode_3"
    t.string   "encrypted_passcode_4"
    t.string   "passcode_encrypt_salt",                 null: false
    t.datetime "last_collected_at"
    t.datetime "last_parsed_at"
    t.datetime "last_synced_at"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.index ["account_uid"], name: "index_synchronizers_on_account_uid"
    t.index ["last_synced_at"], name: "index_synchronizers_on_last_synced_at"
    t.index ["type"], name: "index_synchronizers_on_type"
    t.index ["uid"], name: "index_synchronizers_on_uid", unique: true
    t.index ["user_id"], name: "index_synchronizers_on_user_id"
  end

  create_table "transaction_categorization_cases", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "words"
    t.string   "category_code"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "transaction_uid"
    t.index ["category_code"], name: "index_transaction_categorization_cases_on_category_code"
    t.index ["transaction_uid"], name: "index_transaction_categorization_cases_on_transaction_uid"
    t.index ["user_id"], name: "index_transaction_categorization_cases_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string   "uid",                                    null: false
    t.string   "account_uid",                            null: false
    t.integer  "amount",                                 null: false
    t.text     "description"
    t.string   "category_code"
    t.string   "tags"
    t.text     "note"
    t.datetime "datetime",                               null: false
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "ignore_in_statistics",   default: false, null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "separated"
    t.string   "parent_transaction_uid"
    t.string   "kind"
    t.index ["account_uid"], name: "index_transactions_on_account_uid"
    t.index ["category_code"], name: "index_transactions_on_category_code"
    t.index ["ignore_in_statistics"], name: "index_transactions_on_ignore_in_statistics"
    t.index ["kind"], name: "index_transactions_on_kind"
    t.index ["parent_transaction_uid"], name: "index_transactions_on_parent_transaction_uid"
    t.index ["separated"], name: "index_transactions_on_separated"
    t.index ["uid"], name: "index_transactions_on_uid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email",                        default: "", null: false
    t.string   "encrypted_password",           default: "", null: false
    t.datetime "password_set_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",                default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "unconfirmed_email"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",              default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "mobile"
    t.string   "unconfirmed_mobile"
    t.string   "mobile_confirmation_token"
    t.datetime "mobile_confirmation_sent_at"
    t.integer  "mobile_confirm_tries",         default: 0,  null: false
    t.string   "external_profile_picture_url"
    t.string   "external_cover_photo_url"
    t.string   "fb_id"
    t.string   "fb_email"
    t.text     "fb_access_token"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "default_account_uid"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["default_account_uid"], name: "index_users_on_default_account_uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["fb_email"], name: "index_users_on_fb_email"
    t.index ["fb_id"], name: "index_users_on_fb_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

end
