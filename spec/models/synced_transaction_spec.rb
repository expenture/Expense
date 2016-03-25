require 'rails_helper'

RSpec.describe SyncedTransaction, type: :model do
  describe "instance" do
    let(:synchronizer) { create(:synchronizer) }
    let(:syncing_account) { synchronizer.accounts.create!(uid: SecureRandom.uuid, name: 'A Syncing Account') }
    subject(:synced_transaction) do
      t = syncing_account.transactions.create!(uid: SecureRandom.uuid, amount: -100_000, on_record: true)
      Transaction.find(t.id)
    end

    its(:kind) { is_expected.to eq('synced') }
    its(:class) { is_expected.to eq(SyncedTransaction) }

    it "has immutable amount" do
      expect do
        synced_transaction.amount = 200_000
        synced_transaction.save!
      end.to raise_error
    end

    it "can't be destroyed" do
      expect do
        synced_transaction.destroy!
      end.to raise_error
    end
  end
end
