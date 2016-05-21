# == Schema Information
#
# Table name: accounts
#
# *id*::               <tt>integer, not null, primary key</tt>
# *user_id*::          <tt>integer, not null</tt>
# *uid*::              <tt>string, not null</tt>
# *kind*::             <tt>string</tt>
# *type*::             <tt>string, default("cash"), not null</tt>
# *name*::             <tt>string, not null</tt>
# *currency*::         <tt>string, default("TWD"), not null</tt>
# *balance*::          <tt>integer, default(0), not null</tt>
# *synchronizer_uid*:: <tt>string</tt>
# *created_at*::       <tt>datetime, not null</tt>
# *updated_at*::       <tt>datetime, not null</tt>
#
# Indexes
#
#  index_accounts_on_kind              (kind)
#  index_accounts_on_synchronizer_uid  (synchronizer_uid)
#  index_accounts_on_type              (type)
#  index_accounts_on_uid               (uid) UNIQUE
#  index_accounts_on_user_id           (user_id)
#--
# == Schema Information End
#++

class Account < ApplicationRecord
  self.inheritance_column = :kind
  acts_as_paranoid

  belongs_to :user
  has_many :transactions,
           primary_key: :uid, foreign_key: :account_uid, dependent: :destroy
  has_many :account_identifiers,
           primary_key: :uid, foreign_key: :account_uid

  validates :user, :uid, :type, :name, :currency, :balance, presence: true
  validates :uid, uniqueness: true

  before_save :set_kind

  def default?
    return false unless persisted?
    reload
    user.default_account_uid == uid
  end

  def syncing?
    kind == 'syncing'
  end

  def destroy
    if default?
      errors.add :base, 'Cannot destroy a default account'
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
