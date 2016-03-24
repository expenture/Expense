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
