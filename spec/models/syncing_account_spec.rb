require 'rails_helper'

RSpec.describe SyncingAccount, type: :model do
  describe "instance" do
    let(:synchronizer) { create(:synchronizer) }
    subject(:syncing_account) { synchronizer.accounts.create!(uid: SecureRandom.uuid, name: 'A Syncing Account') }

    its(:kind) { is_expected.to eq('syncing') }
    its(:class) { is_expected.to eq(SyncingAccount) }
    its(:user_id) { is_expected.to eq(synchronizer.user_id) }

    it "can't be destroyed" do
      expect do
        synced_transaction.destroy!
      end.to raise_error
    end

    describe "transaction" do
      subject(:transaction) do
        t = syncing_account.transactions.create!(uid: SecureRandom.uuid, amount: 100_000)
        Transaction.find(t.id)
      end

      its(:kind) { is_expected.to eq('synced') }
      its(:class) { is_expected.to eq(SyncedTransaction) }
    end
  end
end
