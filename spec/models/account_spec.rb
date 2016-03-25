require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "instance" do
    subject(:account) { create(:account) }

    its(:kind) { is_expected.to eq(nil) }
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

      its(:kind) { is_expected.to eq('syncing') }
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

  describe "default builded transaction" do
    let(:account) { create(:account) }
    subject(:transaction) { account.transactions.build }

    its(:on_record) { is_expected.to eq(true) }
  end
end
