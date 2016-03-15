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

    context "has an separated children created" do
      before do
        transaction.separating_children.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.reload
      end

      it { is_expected.to be_separated }
    end

    context "has all separated children removed" do
      before do
        transaction.separating_children.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.separating_children.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.separating_children.destroy_all
      end

      it { is_expected.not_to be_separated }
    end

    describe "parent_transaction_uid" do
      it "should be immutable" do
        expect do
          transaction.parent_transaction_uid = create(:transaction).uid
          transaction.save!
        end.to raise_error
      end
    end
  end

  describe "instance that is a separated children" do
    let(:account) { create(:account, balance: 0) }
    subject(:parent_transaction) { create(:transaction, account: account, amount: -100_000) }
    subject(:transaction) { create(:transaction, account: account, amount: -100_000, parent_transaction: parent_transaction) }

    context "after created" do
      it "does not update the account balance" do
        parent_transaction
        expect(account.balance).to eq(-100_000)

        transaction
        account.reload

        expect(account.balance).to eq(-100_000)
      end
    end

    context "after updated" do
      it "does not update the account balance" do
        parent_transaction
        transaction
        expect(account.balance).to eq(-100_000)

        transaction.update_attributes(amount: 800_000)
        transaction.save!
        account.reload

        expect(account.balance).to eq(-100_000)

        transaction.update_attributes(amount: -800_000)
        transaction.save!
        account.reload

        expect(account.balance).to eq(-100_000)
      end
    end

    context "after destroyed" do
      it "does not update the account balance" do
        parent_transaction
        transaction

        expect(account.balance).to eq(-100_000)

        transaction.destroy!
        account.reload

        expect(account.balance).to eq(-100_000)
      end
    end

    it "can't have separated children" do
      expect do
        transaction.separating_children.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
      end.to raise_error

      expect do
        create(:transaction, account: account, amount: -100_000, parent_transaction: transaction)
      end.to raise_error
    end

    describe "parent_transaction_uid" do
      it "should be immutable" do
        expect do
          transaction.parent_transaction_uid = nil
          transaction.save!
        end.to raise_error
      end
    end
  end
end
