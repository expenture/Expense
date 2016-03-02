class Transaction < ApplicationRecord
  belongs_to :account,
             primary_key: :uid, foreign_key: :account_uid

  validates :account, :uid, :amount, :datetime, presence: true

  before_validation :set_default_date, :standardize_attrs
  after_create :update_account_on_create
  before_update :update_account_on_update
  before_destroy :update_account_on_destroy

  private

  def set_default_date
    self.datetime = Time.now if self.datetime.blank?
  end

  def standardize_attrs
    if ignore_in_statistics == nil
      self.ignore_in_statistics = false
    elsif ignore_in_statistics == 'nil'
      self.ignore_in_statistics = nil
    end
  end

  def update_account_on_create
    update_account_balance(:create)
    self.account.save!
  end

  def update_account_on_update
    update_account_balance(:update)
    self.account.save!
  end

  def update_account_on_destroy
    update_account_balance(:destroy)
    self.account.save!
  end

  def update_account_balance(event)
    return if account.blank?
    case event
    when :create
      account.balance += amount
    when :update
      return unless amount_changed?
      amount_diff = amount - amount_was
      account.balance += amount_diff
    when :destroy
      account.balance -= amount
    end
  end
end
