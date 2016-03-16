class Account < ApplicationRecord
  self.inheritance_column = :kind

  belongs_to :user
  has_many :transactions,
           primary_key: :uid, foreign_key: :account_uid
  has_many :synchronizer_parsed_data, class_name: 'Synchronizer::ParsedData',
                                      primary_key: :uid, foreign_key: :account_uid

  validates :user, :uid, :type, :name, :currency, :balance, presence: true
  validates :uid, uniqueness: true

  before_save :set_kind

  def default?
    return false unless persisted?
    reload
    user.default_account_uid == uid
  end

  def destroy
    if default?
      errors.add :base, 'Cannot destroy a default account'
      return false
    elsif kind == 'syncing'
      errors.add :base, 'Cannot destroy a syncing account'
      return false
    else
      super
    end
  end

  private

  def set_kind
    if synchronizer_uid.present?
      self.kind = 'syncing'
    end
  end

  class << self
    # Override Rails STI class finding
    # @api private
    def find_sti_class(type_name)
      case type_name
      when 'syncing'
        SyncingAccount
      end
    end

    # Override Rails STI class name
    # @api private
    def sti_name
      case name
      when 'SyncingAccount'
        'syncing'
      end
    end
  end
end
