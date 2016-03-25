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
