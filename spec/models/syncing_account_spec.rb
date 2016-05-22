require 'rails_helper'

RSpec.describe SyncingAccount, type: :model do
  describe "instance" do
    let(:synchronizer) { create(:synchronizer) }
    subject(:syncing_account) { synchronizer.accounts.create!(uid: SecureRandom.uuid, name: 'A Syncing Account') }

    its(:type) { is_expected.to eq('syncing') }
    its(:class) { is_expected.to eq(SyncingAccount) }
    its(:user_id) { is_expected.to eq(synchronizer.user_id) }

    it "can't be destroyed" do
      expect do
        synced_transaction.destroy!
      end.to raise_error
    end

    describe "transaction" do
      subject(:transaction) do
        t = syncing_account.transactions.create!(uid: SecureRandom.uuid, amount: 100_000, on_record: true)
        Transaction.find(t.id)
      end

      its(:type) { is_expected.to eq('synced') }
      its(:class) { is_expected.to eq(SyncedTransaction) }
    end
  end

  describe "default builded transaction" do
    let(:account) { create(:syncing_account) }
    subject(:transaction) { account.transactions.build }

    its(:on_record) { is_expected.to eq(false) }

    context "on_record specified to be true" do
      subject(:transaction) { account.transactions.build(on_record: true) }

      its(:on_record) { is_expected.to eq(true) }
    end

    context "with a separate_transaction_uid" do
      subject(:transaction) { account.transactions.build(separate_transaction_uid: 'xxx') }

      its(:on_record) { is_expected.to eq(nil) }
    end
  end
end
