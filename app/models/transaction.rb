class Transaction < ApplicationRecord
  self.inheritance_column = :kind

  scope :for_statistics, -> { where(ignore_in_statistics: false) }
  scope :virtual, -> { where.not(separate_transaction_uid: nil) }
  scope :real, -> { where(separate_transaction_uid: nil) }
  scope :separated, -> { where(separated: true) }
  scope :not_separated, -> { where(separated: false) }
  scope :on_record, -> { where(on_record: true) }
  scope :not_on_record, -> { where(on_record: false) }

  belongs_to :account,
             primary_key: :uid, foreign_key: :account_uid
  has_one :user, through: :account, autosave: false
  has_many :separating_transactions, class_name: 'VirtualTransaction',
                                     primary_key: :uid,
                                     foreign_key: :separate_transaction_uid
  has_many :not_on_record_copies, class_name: 'NotOnRecordTransaction',
                                  primary_key: :uid,
                                  foreign_key: :record_transaction_uid
  belongs_to :synchronizer_parsed_data, class_name: 'Synchronizer::ParsedData',
                                        primary_key: :uid,
                                        foreign_key: :synchronizer_parsed_data_uid

  validates :account, :uid, :amount, :datetime, presence: true
  validate :not_separating_a_virtual_transaction
  validate :immutable_separate_transaction_uid, on: :update
  validate :record_transaction_uid_must_be_nil_if_on_record,
           :record_transaction_is_valid_if_record_transaction_uid_is_set
  validate :immutable_on_record, on: :update

  after_initialize :init_on_record
  before_validation :set_kind, :set_default_date, :standardize_attrs
  before_validation :set_attributes_for_virtual_transaction,
                    :set_separated_if_having_virtual_transaction,
                    :set_ignore_in_statistics_for_separated_transaction
  before_validation :set_ignore_in_statistics_for_not_on_record_copy
  after_create :update_account_on_create
  before_update :update_account_on_update
  after_save :touch_separate_transaction
  before_destroy :update_account_on_destroy
  after_destroy :touch_separate_transaction

  def virtual?
    separate_transaction_uid.present?
  end

  def has_a_actual_record?
    on_record? || record_transaction_uid.present?
  end

  def not_on_record_copy?
    !on_record? && record_transaction_uid.present?
  end

  private

  def init_on_record
    return unless on_record.nil?
    return if virtual?
    if account.is_a?(SyncingAccount)
      self.on_record = false
    else
      self.on_record = true
    end
  end

  def separate_transaction
    @separate_transaction ||= Transaction.find_by(uid: separate_transaction_uid)
  end

  def record_transaction
    @record_transaction ||= Transaction.find_by(uid: record_transaction_uid)
  end

  def not_separating_a_virtual_transaction
    return unless virtual?
    return unless separate_transaction.virtual?
    errors.add(:separate_transaction, 'is a virtual transaction, can\'t separate a virtual transaction')
  end

  def immutable_separate_transaction_uid
    return unless separate_transaction_uid_changed?
    errors.add(:separate_transaction_uid, 'is immutable')
  end

  def record_transaction_uid_must_be_nil_if_on_record
    return unless on_record?
    return if record_transaction_uid.nil?
    errors.add(:record_transaction_uid, 'must not be set for a recorded transaction')
  end

  def record_transaction_is_valid_if_record_transaction_uid_is_set
    return if record_transaction_uid.blank?
    errors.add(:record_transaction_uid, 'is invalid') && return if record_transaction.blank?
    errors.add(:record_transaction_uid, 'is invalid') unless record_transaction.account_uid == account_uid
    errors.add(:record_transaction_uid, 'refers to a transaction that is not in record') unless record_transaction.on_record?
  end

  def immutable_on_record
    return unless on_record_changed?
    errors.add(:on_record, 'is immutable')
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

  def set_attributes_for_virtual_transaction
    return unless virtual?
    self.on_record = nil
    self.account_uid ||= separate_transaction.account_uid
  end

  def set_ignore_in_statistics_for_separated_transaction
    return unless separated?
    self.ignore_in_statistics = true
  end

  def set_ignore_in_statistics_for_not_on_record_copy
    self.ignore_in_statistics = has_a_actual_record? if on_record == false
  end

  def set_kind
    if account.present? && account.kind == 'syncing' && on_record?
      self.kind = 'synced'
    elsif on_record == false
      self.kind = 'not_on_record'
    elsif virtual?
      self.kind = 'virtual'
    end
  end

  def update_account_on_create
    return unless on_record?
    update_account_balance(:create)
    account.save!
  end

  def update_account_on_update
    return unless on_record?
    update_account_balance(:update)
    account.save!
  end

  def update_account_on_destroy
    return unless on_record?
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

  def set_separated_if_having_virtual_transaction
    self.separated = separating_transactions.present?
  end

  def touch_separate_transaction
    return unless virtual?
    separate_transaction.reload
    separate_transaction.touch
    separate_transaction.save!
  end

  class << self
    # Override Rails STI class finding
    # @api private
    def find_sti_class(type_name)
      case type_name
      when 'virtual'
        VirtualTransaction
      when 'synced'
        SyncedTransaction
      when 'not_on_record'
        NotOnRecordTransaction
      else
        Transaction
      end
    end

    # Override Rails STI class name
    # @api private
    def sti_name
      case name
      when 'VirtualTransaction'
        'virtual'
      when 'SyncedTransaction'
        'synced'
      when 'NotOnRecordTransaction'
        'not_on_record'
      end
    end
  end
end
