# == Schema Information
#
# Table name: accounts
#
# *id*::               <tt>integer, not null, primary key</tt>
# *user_id*::          <tt>integer, not null</tt>
# *uid*::              <tt>string, not null</tt>
# *type*::             <tt>string, default("cash"), not null</tt>
# *name*::             <tt>string, not null</tt>
# *currency*::         <tt>string, default("TWD"), not null</tt>
# *balance*::          <tt>integer, default(0), not null</tt>
# *created_at*::       <tt>datetime, not null</tt>
# *updated_at*::       <tt>datetime, not null</tt>
# *kind*::             <tt>string</tt>
# *synchronizer_uid*:: <tt>string</tt>
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

class SyncingAccount < Account
  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid

  validates :synchronizer, presence: true

  before_validation :init_user

  def destroy
    errors.add :base, 'Cannot destroy a syncing account'
    return false
  end

  private

  def init_user
    return if synchronizer.blank?
    self.user ||= synchronizer.user
  end
end
