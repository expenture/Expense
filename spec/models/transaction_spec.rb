require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:account) { create(:account, balance: 0) }

  describe "a normal transaction instance" do
    subject(:transaction) { create(:transaction, account: account, amount: -100_000) }

    describe "account_uid attribute" do
      it "should be immutable" do
        expect do
          transaction.account_uid = create(:account).uid
          transaction.save!
        end.to raise_error
      end
    end

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

    context "has an separating transaction created" do
      before do
        transaction.separating_transactions.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.reload
      end

      it { is_expected.to be_separated }
    end

    context "has all separating transaction removed" do
      before do
        transaction.separating_transactions.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.separating_transactions.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
        transaction.separating_transactions.destroy_all
      end

      it { is_expected.not_to be_separated }
    end

    describe "separate_transaction_uid attribute" do
      it "should be immutable" do
        expect do
          transaction.separate_transaction_uid = create(:transaction).uid
          transaction.save!
        end.to raise_error
      end
    end

    describe "on_record attribute" do
      it "defaults to true" do
        expect(transaction.on_record).to eq(true)
      end

      it "should be immutable" do
        expect do
          transaction.on_record = false
          transaction.save!
        end.to raise_error
      end
    end

    describe "record_transaction_uid attribute" do
      it "must be blank" do
        expect do
          transaction.record_transaction_uid = create(:transaction, account: account, amount: -100_000).uid
          transaction.save!
        end.to raise_error
      end
    end
  end

  describe "instance that is a virtual transaction (i.e. separating transaction)" do
    let(:separated_transaction) { create(:transaction, account: account, amount: -100_000) }
    subject(:transaction) do
      # If a transaction has its separate_transaction_uid set,
      # then it is considered to be a virtual transaction
      create(:transaction, account: account, amount: -100_000, separate_transaction_uid: separated_transaction.uid)
    end

    its(:kind) { should eq('virtual') }
    # A virtual transaction will not be considered to be on_record or not,
    # so its on_record value must be nil
    its(:on_record) { is_expected.to be_nil }

    context "after created" do
      it "does not update the account balance" do
        separated_transaction
        expect(account.balance).to eq(-100_000)

        transaction
        account.reload

        expect(account.balance).to eq(-100_000)
      end

      it "lets the separated transaction to be ignore_in_statistics" do
        separated_transaction
        expect(separated_transaction.ignore_in_statistics).to eq(false)

        transaction
        separated_transaction.reload

        expect(separated_transaction.ignore_in_statistics).to eq(true)
      end

      it "lets the separated transaction to be separated" do
        separated_transaction
        expect(separated_transaction.separated).to eq(false)

        transaction
        separated_transaction.reload

        expect(separated_transaction.separated).to eq(true)
      end
    end

    context "after updated" do
      it "does not update the account balance" do
        separated_transaction
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
        separated_transaction
        transaction

        expect(account.balance).to eq(-100_000)

        transaction.destroy!
        account.reload

        expect(account.balance).to eq(-100_000)
      end

      it "lets the separated transaction to be not separated" do
        transaction
        separated_transaction.reload

        expect(separated_transaction.separated).to eq(true)

        transaction.destroy!
        separated_transaction.reload

        expect(separated_transaction.separated).to eq(false)
      end
    end

    it "can't have separated children" do
      expect do
        transaction.separating_transactions.create!(uid: SecureRandom.uuid, description: 'Some description', amount: 100_000)
      end.to raise_error

      expect do
        create(:transaction, account: account, amount: -100_000, separate_transaction: transaction)
      end.to raise_error
    end

    describe "separate_transaction_uid" do
      it "should be immutable" do
        expect do
          transaction.separate_transaction_uid = nil
          transaction.save!
        end.to raise_error
      end
    end
  end

  describe "instance that is a not-on-record transaction" do
    subject(:transaction) { create(:transaction, account: account, amount: -100_000, on_record: false) }

    its(:kind) { should eq('not_on_record') }

    describe "record_transaction_uid" do
      it "can be set" do
        transaction.record_transaction_uid = create(:transaction, account: account, amount: -100_000).uid
        transaction.save!
      end

      it "will be validated" do
        expect do
          transaction.record_transaction_uid = 'xxx'
          transaction.save!
        end.to raise_error

        expect do
          transaction.record_transaction_uid = create(:transaction).uid
          transaction.save!
        end.to raise_error

        expect do
          transaction.record_transaction_uid = create(:transaction, account: account, amount: -100_000, on_record: false).uid
          transaction.save!
        end.to raise_error
      end
    end

    context "has an on-record transaction" do
      before do
        transaction.record_transaction_uid = create(:transaction, account: account, amount: -100_000).uid
        transaction.save!
      end

      its(:ignore_in_statistics) { is_expected.to be(true) }
    end

    context "does not have an on-record transaction" do
      before do
        transaction.record_transaction_uid = nil
        transaction.save!
      end

      its(:ignore_in_statistics) { is_expected.to be(false) }
    end
  end
end
