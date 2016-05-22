require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "instance" do
    subject(:account) { create(:account) }

    its(:type) { is_expected.to eq(nil) }
    its(:class) { is_expected.to eq(Account) }

    context "set as default by the user" do
      subject(:account) { create(:account, :default) }

      it { is_expected.to be_default }

      it "can't be destroyed" do
        expect { account.destroy! }.to raise_error
      end
    end

    context "not set as default by the user" do
      subject(:account) { create(:account) }

      it { is_expected.not_to be_default }

      it "can be destroyed" do
        expect { account.destroy! }.not_to raise_error
      end
    end

    context "created with a synchronizer" do
      subject(:account) do
        a = create(:account, synchronizer_uid: 'someting')
        Account.find(a.id)
      end

      its(:type) { is_expected.to eq('syncing') }
      its(:class) { is_expected.to eq(SyncingAccount) }

      it "can't be destroyed" do
        expect { account.destroy! }.to raise_error
      end

      it "can't be set to default" do
        expect do
          user = account.user
          user.default_account_uid = account.uid
          user.save!
        end.to raise_error
      end
    end
  end

  context "when destroyed" do
    it "is softly destroyed" do
      create(:account, uid: 'destroyed-account').destroy

      account = Account.find_by(uid: 'destroyed-account')
      expect(account).to be_nil

      destroyed_account = Account.only_deleted.find_by(uid: 'destroyed-account')
      expect(destroyed_account).not_to be_nil
      expect(destroyed_account.deleted_at).not_to be_nil
    end

    it "softly destroys all transactions on it" do
      account = create(:account, uid: 'destroyed-account')
      create(:transaction, account: account, uid: 'destroyed-account-transaction-1')
      create(:transaction, account: account, uid: 'destroyed-account-transaction-2')
      account.destroy

      transaction_1 = Transaction.find_by(uid: 'destroyed-account-transaction-1')
      expect(transaction_1).to be_nil
      transaction_2 = Transaction.find_by(uid: 'destroyed-account-transaction-2')
      expect(transaction_2).to be_nil

      destroyed_transaction_1 = Transaction.only_deleted.find_by(uid: 'destroyed-account-transaction-1')
      expect(destroyed_transaction_1).not_to be_nil
      expect(destroyed_transaction_1.account).not_to be_nil
      destroyed_transaction_2 = Transaction.only_deleted.find_by(uid: 'destroyed-account-transaction-2')
      expect(destroyed_transaction_2).not_to be_nil
      expect(destroyed_transaction_2.account).not_to be_nil
    end
  end

  describe "default builded transaction" do
    let(:account) { create(:account) }
    subject(:transaction) { account.transactions.build }

    its(:on_record) { is_expected.to eq(true) }
  end
end
