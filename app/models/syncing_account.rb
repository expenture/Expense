class SyncingAccount < Account
  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid
  has_many :transactions, class_name: 'SyncedTransaction',
                          primary_key: :uid, foreign_key: :account_uid

  before_validation :init_user

  private

  def init_user
    return if synchronizer.blank?
    self.user ||= synchronizer.user
  end
end
