class Transaction < ApplicationRecord
  scope :ignore_in_statistics, -> { where(ignore_in_statistics: false, separated: false) }

  belongs_to :account,
             primary_key: :uid, foreign_key: :account_uid
  has_many :synchronizer_parsed_data, class_name: 'Synchronizer::ParsedData',
                                      primary_key: :uid, foreign_key: :transaction_uid
  has_many :separating_children, class_name: 'Transaction',
                                 primary_key: :uid,
                                 foreign_key: :parent_transaction_uid
  belongs_to :parent_transaction, class_name: 'Transaction',
                                  primary_key: :uid,
                                  foreign_key: :parent_transaction_uid

  validates :account, :uid, :amount, :datetime, presence: true
  validate :separating_children_not_separated,
           :not_separating_a_separating_child
  validate :immutable_parent_transaction_uid, on: :update

  before_validation :set_default_date, :standardize_attrs,
                    :set_account_for_separating_children
  after_create :update_account_on_create
  before_update :update_account_on_update
  after_touch :set_separated_if_having_separating_children
  after_save :touch_parent_transaction
  before_destroy :update_account_on_destroy

  private

  def separating_children_not_separated
    return if parent_transaction_uid.blank?
    return if separating_children.blank?
    errors.add(:separating_children, 'A separated children can\'t be separated')
  end

  def not_separating_a_separating_child
    return if parent_transaction_uid.blank?
    return if parent_transaction.parent_transaction_uid.blank?
    errors.add(:parent_transaction, 'Can\'t separate a separating child')
  end

  def immutable_parent_transaction_uid
    return unless parent_transaction_uid_changed?
    errors.add(:parent_transaction_uid, 'is immutable')
  end

  def set_default_date
    self.datetime = Time.now if datetime.blank?
  end

  def standardize_attrs
    if ignore_in_statistics.nil?
      self.ignore_in_statistics = false
    elsif ignore_in_statistics == 'nil'
      self.ignore_in_statistics = nil
    end
  end

  def set_account_for_separating_children
    return unless parent_transaction.present?
    self.account_uid ||= parent_transaction.account_uid
  end

  def update_account_on_create
    return if parent_transaction_uid.present?
    update_account_balance(:create)
    account.save!
  end

  def update_account_on_update
    return if parent_transaction_uid.present?
    update_account_balance(:update)
    account.save!
  end

  def touch_parent_transaction
    return unless parent_transaction.present?
    parent_transaction.touch
    parent_transaction.save!
  end

  def update_account_on_destroy
    return if parent_transaction_uid.present?
    update_account_balance(:destroy)
    account.save!
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

  def set_separated_if_having_separating_children
    if separating_children.present?
      self.separated = true
    else
      self.separated = false
    end
  end
end
