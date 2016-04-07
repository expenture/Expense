# == Schema Information
#
# Table name: transactions
#
# *id*::                           <tt>integer, not null, primary key</tt>
# *uid*::                          <tt>string, not null</tt>
# *account_uid*::                  <tt>string, not null</tt>
# *kind*::                         <tt>string</tt>
# *amount*::                       <tt>integer, not null</tt>
# *description*::                  <tt>text</tt>
# *category_code*::                <tt>string</tt>
# *tags*::                         <tt>string</tt>
# *note*::                         <tt>text</tt>
# *datetime*::                     <tt>datetime, not null</tt>
# *latitude*::                     <tt>float</tt>
# *longitude*::                    <tt>float</tt>
# *party_type*::                   <tt>string</tt>
# *party_code*::                   <tt>string</tt>
# *party_name*::                   <tt>string</tt>
# *external_image_url*::           <tt>string</tt>
# *separated*::                    <tt>boolean, default(FALSE), not null</tt>
# *separate_transaction_uid*::     <tt>string</tt>
# *on_record*::                    <tt>boolean</tt>
# *record_transaction_uid*::       <tt>string</tt>
# *synchronizer_parsed_data_uid*:: <tt>string</tt>
# *ignore_in_statistics*::         <tt>boolean, default(FALSE), not null</tt>
# *manually_edited_at*::           <tt>datetime</tt>
# *created_at*::                   <tt>datetime, not null</tt>
# *updated_at*::                   <tt>datetime, not null</tt>
#
# Indexes
#
#  index_transactions_on_account_uid                   (account_uid)
#  index_transactions_on_category_code                 (category_code)
#  index_transactions_on_ignore_in_statistics          (ignore_in_statistics)
#  index_transactions_on_kind                          (kind)
#  index_transactions_on_manually_edited_at            (manually_edited_at)
#  index_transactions_on_on_record                     (on_record)
#  index_transactions_on_record_transaction_uid        (record_transaction_uid)
#  index_transactions_on_separate_transaction_uid      (separate_transaction_uid)
#  index_transactions_on_separated                     (separated)
#  index_transactions_on_synchronizer_parsed_data_uid  (synchronizer_parsed_data_uid)
#  index_transactions_on_uid                           (uid) UNIQUE
#--
# == Schema Information End
#++

class Transaction < ApplicationRecord
  self.inheritance_column = :kind

  scope :for_statistics, -> { where(ignore_in_statistics: false) }
  scope :virtual, -> { where.not(separate_transaction_uid: nil) }
  scope :not_virtual, -> { where(separate_transaction_uid: nil) }
  scope :separated, -> { where(separated: true) }
  scope :not_separated, -> { where(separated: false) }
  scope :on_record, -> { where(on_record: true) }
  scope :not_on_record, -> { where(on_record: false) }
  scope :not_on_record_copy, -> { where(on_record: false).where.not(record_transaction_uid: nil) }
  scope :possible_copy, -> (amount, datetime, party_type: nil, party_code: nil) {
    datetime = DateTime.parse(datetime) unless datetime.is_a?(Date) ||
                                               datetime.is_a?(ActiveSupport::TimeWithZone)
    where(
      amount: amount,
      datetime: (datetime - 25.hours)..(datetime + 25.hours),
      party_type: [nil, party_type],
      party_code: [nil, party_code]
    )
  }
  scope :possible_on_record_copy, -> (amount, datetime, party_type: nil, party_code: nil) {
    on_record.possible_copy(amount, datetime, party_type: party_type, party_code: party_code)
  }

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
  validate :separate_transaction_uid_is_valid,
           :not_separating_a_virtual_transaction
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

  def synced?
    kind == 'synced'
  end

  def manually_edited
    self.manually_edited_at.present?
  end

  def manually_edited?
    self.manually_edited_at.present?
  end

  def manually_edited=(bool)
    if bool
      self.manually_edited_at ||= Time.now
    else
      self.manually_edited_at = nil
    end
  end

  def image_url
    external_image_url
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

  def separate_transaction_uid_is_valid
    return if separate_transaction_uid.blank?
    if separate_transaction.blank? ||
       separate_transaction.account_uid != account_uid
      errors.add(:separate_transaction_uid, 'is invalid, the specified transaction does not exists')
    end
  end

  def not_separating_a_virtual_transaction
    return unless virtual?
    return if separate_transaction.blank?
    return unless separate_transaction.virtual?
    errors.add(:separate_transaction_uid, 'is pointed to a virtual transaction, can\'t separate a virtual transaction')
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
