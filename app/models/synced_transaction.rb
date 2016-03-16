class SyncedTransaction < Transaction
  validate :immutable_amount, on: :update

  def destroy
    errors.add :base, 'a SyncedTransaction cannot be destroyed'
    return false
  end

  private

  def immutable_amount
    return unless amount_changed?
    errors.add(:amount, 'is immutable for synced transaction')
  end
end
