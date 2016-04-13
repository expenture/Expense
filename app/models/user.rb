# == Schema Information
#
# Table name: users
#
# *id*::                           <tt>integer, not null, primary key</tt>
# *name*::                         <tt>string</tt>
# *email*::                        <tt>string, default(""), not null</tt>
# *encrypted_password*::           <tt>string, default(""), not null</tt>
# *password_set_at*::              <tt>datetime</tt>
# *reset_password_token*::         <tt>string</tt>
# *reset_password_sent_at*::       <tt>datetime</tt>
# *sign_in_count*::                <tt>integer, default(0), not null</tt>
# *current_sign_in_at*::           <tt>datetime</tt>
# *last_sign_in_at*::              <tt>datetime</tt>
# *current_sign_in_ip*::           <tt>string</tt>
# *last_sign_in_ip*::              <tt>string</tt>
# *unconfirmed_email*::            <tt>string</tt>
# *confirmation_token*::           <tt>string</tt>
# *confirmed_at*::                 <tt>datetime</tt>
# *confirmation_sent_at*::         <tt>datetime</tt>
# *failed_attempts*::              <tt>integer, default(0), not null</tt>
# *unlock_token*::                 <tt>string</tt>
# *locked_at*::                    <tt>datetime</tt>
# *mobile*::                       <tt>string</tt>
# *unconfirmed_mobile*::           <tt>string</tt>
# *mobile_confirmation_token*::    <tt>string</tt>
# *mobile_confirmation_sent_at*::  <tt>datetime</tt>
# *mobile_confirm_tries*::         <tt>integer, default(0), not null</tt>
# *external_profile_picture_url*:: <tt>string</tt>
# *external_cover_photo_url*::     <tt>string</tt>
# *fb_id*::                        <tt>string</tt>
# *fb_email*::                     <tt>string</tt>
# *fb_access_token*::              <tt>text</tt>
# *created_at*::                   <tt>datetime, not null</tt>
# *updated_at*::                   <tt>datetime, not null</tt>
# *default_account_uid*::          <tt>string</tt>
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_default_account_uid   (default_account_uid)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_fb_email              (fb_email)
#  index_users_on_fb_id                 (fb_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#--
# == Schema Information End
#++

class User < ApplicationRecord
  include RailsSettings::Extend

  attr_accessor :from
  devise :database_authenticatable, :omniauthable, :registerable, :confirmable,
         :lockable, :recoverable, :trackable, :validatable,
         omniauth_providers: [:facebook]

  has_many :accounts
  belongs_to :default_account, class_name: :Account,
                               primary_key: :uid, foreign_key: :default_account_uid,
                               optional: true
  has_many :transactions, through: :accounts
  has_many :transaction_categorization_cases
  has_many :synchronizers
  has_many :account_identifiers

  validates :default_account, presence: true, on: :update
  validate :default_account_is_not_a_syncing_one, on: :update

  after_create :create_default_account
  before_validation :check_password

  def transaction_category_set
    @transaction_category_set ||= TransactionCategorySet.new(self)
  end

  def link_to_facebook_by_data(data, save: true)
    self.name = data[:name] if self.name.blank?

    self.external_profile_picture_url = data[:picture_url] if data[:picture_url].present?
    self.external_cover_photo_url = data[:cover_url] if data[:cover_url].present?

    self.fb_id = data[:id]
    self.fb_email = data[:email]

    self.save! if save

    return self
  end

  def link_to_facebook_by_access_token(access_token)
    self.link_to_facebook_by_data(FacebookService.user_data_from_facebook_access_token(access_token), save: false)

    self.fb_access_token = access_token
    self.save!

    return self
  end

  def send_confirmation_instructions
    return if from == 'skip_send_confirmation_instructions'

    if from == 'facebook'
      confirm
      return
    end

    super
  end

  private

  def create_default_account
    self.default_account = Account.new(user_id: id, uid: "#{id}-#{SecureRandom.uuid}", name: 'default')
    self.default_account.save!
    self.save!
  end

  def check_password
    if self.from == 'facebook'
      self.password = SecureRandom.hex(36) if encrypted_password.blank?
    elsif persisted? == false
      self.password_set_at = Time.now
    else
      self.password_set_at = Time.now if encrypted_password_changed?
    end
  end

  def default_account_is_not_a_syncing_one
    return unless default_account_uid_changed?
    return unless default_account && default_account.kind == 'syncing'
    errors.add(:default_account_uid, 'can not be a syncing account')
  end

  class << self
    def from_facebook_access_token(access_token)
      fb_user_data = FacebookService.user_data_from_facebook_access_token(access_token)

      if fb_user_data
        user = User.find_by(fb_id: fb_user_data[:id]) ||
               User.find_by(fb_email: fb_user_data[:email]) ||
               User.find_by(email: fb_user_data[:email]) ||
               User.new(email: fb_user_data[:email], name: fb_user_data[:name])

        user.from = 'facebook'
        user.fb_access_token = access_token
        user.link_to_facebook_by_data(fb_user_data, save: false) if user.fb_id.blank?

        user.save!
        return user
      else
        return nil
      end
    end
  end
end
