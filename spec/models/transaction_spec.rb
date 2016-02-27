require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "instance" do
    let(:account) { create(:account, balance: 0) }
    subject(:transaction) { create(:transaction, account: account, amount: -100_000) }

    context "after created" do
      it "updates the account balance" do
        expect(account.balance).to eq(0)

        transaction
        account.reload

        expect(account.balance).to eq(-100_000)
      end
    end

    context "after updated" do
      it "updates the account balance" do
        transaction

        expect(account.balance).to eq(-100_000)

        transaction.update_attributes(amount: 500_000)
        transaction.save!
        account.reload

        expect(account.balance).to eq(500_000)


        transaction.update_attributes(amount: -500_000)
        transaction.save!
        account.reload

        expect(account.balance).to eq(-500_000)
      end
    end

    context "after destroyed" do
      it "updates the account balance" do
        transaction

        expect(account.balance).to eq(-100_000)

        transaction.destroy!
        account.reload

        expect(account.balance).to eq(0)
      end
    end

    context "after create failed" do
      it "leaves the account balance unchanged" do
        # This will fail, uid can't be null
        expect { create(:transaction, uid: nil, account: account) }.to raise_error

        account.reload
        expect(account.balance).to eq(0)
      end
    end

    context "after update failed" do
      it "leaves the account balance unchanged" do
        transaction

        expect(account.balance).to eq(-100_000)

        # This will fail, ignore_in_statistics can't be null
        expect { transaction.update_attributes!(uid: nil, amount: 500_000) }.to raise_error

        account.reload
        expect(account.balance).to eq(-100_000)
      end
    end
  end
end
