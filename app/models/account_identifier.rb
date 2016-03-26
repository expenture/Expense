# == Schema Information
#
# Table name: account_identifiers
#
# *id*::                             <tt>integer, not null, primary key</tt>
# *user_id*::                        <tt>integer, not null</tt>
# *type*::                           <tt>string</tt>
# *account_uid*::                    <tt>string</tt>
# *identifier*::                     <tt>string, not null</tt>
# *sample_transaction_description*:: <tt>text</tt>
# *sample_transaction_party_name*::  <tt>string</tt>
# *sample_transaction_amount*::      <tt>integer</tt>
# *sample_transaction_datetime*::    <tt>datetime</tt>
# *created_at*::                     <tt>datetime, not null</tt>
# *updated_at*::                     <tt>datetime, not null</tt>
#
# Indexes
#
#  index_account_identifiers_on_account_uid  (account_uid)
#  index_account_identifiers_on_identifier   (identifier)
#  index_account_identifiers_on_type         (type)
#  index_account_identifiers_on_user_id      (user_id)
#--
# == Schema Information End
#++

class AccountIdentifier < ApplicationRecord
  self.inheritance_column = nil

  scope :identified, -> { where.not(account_uid: nil) }
  scope :unidentified, -> { where(account_uid: nil) }

  belongs_to :user
  belongs_to :account,
             primary_key: :uid, foreign_key: :account_uid

  validates :identifier, :user, presence: true
  validates :identifier, uniqueness: { scope: [:user_id, :type] }
  validate :account_exists_if_account_uid_is_not_blank,
           :account_belongs_to_the_user_if_account_exists

  def identified?
    account_uid.present?
  end

  private

  def account_exists_if_account_uid_is_not_blank
    return if account_uid.blank?
    errors.add(:account_uid, 'is invalid') if account.blank?
  end

  def account_belongs_to_the_user_if_account_exists
    return if account.blank?
    errors.add(:account_uid, 'is invalid') if account.user_id != user_id
  end
end
