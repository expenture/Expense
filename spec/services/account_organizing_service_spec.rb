require 'rails_helper'

RSpec.describe AccountOrganizingService, type: :service do
  describe ".clean" do
    let(:account) { create(:account) }

    it "links all not-on-record transactions to on-record transactions" do
      account.transactions.create!(uid: 'pre_trans_1-1', amount: -100_000, datetime: 3.days.ago + 12.hours, on_record: false)
      account.transactions.create!(uid: 'pre_trans_1-2', amount: -100_000, datetime: 3.days.ago - 12.hours, on_record: false)
      account.transactions.create!(uid: 'real_trans_1', amount: -100_000, datetime: 3.days.ago, on_record: true)
      account.transactions.create!(uid: 'pre_trans_2', amount: -100_000, datetime: 1.day.ago - 24.hours, on_record: false)
      account.transactions.create!(uid: 'real_trans_2', amount: -100_000, datetime: 1.day.ago, on_record: true)
      account.transactions.create!(uid: 'pre_trans_3', amount: -200_000, datetime: 1.day.ago - 24.hours, on_record: false)
      account.transactions.create!(uid: 'real_trans_3', amount: -200_000, datetime: 1.day.ago - 24.hours, on_record: true)

      AccountOrganizingService.clean(account)

      expect(Transaction.find_by(uid: 'pre_trans_1-1')).to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_1-1').record_transaction_uid).to eq('real_trans_1')
      expect(Transaction.find_by(uid: 'pre_trans_1-2')).to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_1-2').record_transaction_uid).to eq('real_trans_1')
      expect(Transaction.find_by(uid: 'pre_trans_2')).to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_2').record_transaction_uid).to eq('real_trans_2')
      expect(Transaction.find_by(uid: 'pre_trans_3')).to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_3').record_transaction_uid).to eq('real_trans_3')
    end

    it "sets the not-on-record transaction to be ignore_in_statistics after linking it to an on-record transaction" do
      account.transactions.create!(uid: 'pre_trans', amount: -100_000, datetime: 1.day.ago, on_record: false)
      account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true)

      expect(Transaction.find_by(uid: 'pre_trans')).not_to be_ignore_in_statistics

      AccountOrganizingService.clean(account)

      expect(Transaction.find_by(uid: 'pre_trans')).to be_ignore_in_statistics
    end

    it "does not effect not-on-record transactions that dosen't have an on-record transaction by a same amount and similar datetime" do
      account.transactions.create!(uid: 'pre_trans_1', amount: -200_000, datetime: 1.day.ago, on_record: false)
      account.transactions.create!(uid: 'pre_trans_2', amount: -100_000, datetime: 3.days.from_now, on_record: false)
      account.transactions.create!(uid: 'real_trans_3', amount: -100_000, datetime: 1.day.ago, on_record: true)

      AccountOrganizingService.clean(account)

      expect(Transaction.find_by(uid: 'pre_trans_1')).not_to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_2')).not_to be_not_on_record_copy
      expect(Transaction.find_by(uid: 'pre_trans_1').record_transaction_uid).to be_blank
      expect(Transaction.find_by(uid: 'pre_trans_2').record_transaction_uid).to be_blank
    end

    context "matching on-record transaction is not manually edited" do
      it "copies the description and note from the not-on-record transaction to the on-record transaction" do
        account.transactions.create!(uid: 'pre_trans', amount: -100_000, datetime: 1.day.ago, on_record: false, description: 'Aha!', note: 'OK!')
        account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true)

        AccountOrganizingService.clean(account)
        real_trans = Transaction.find_by(uid: 'real_trans')

        expect(real_trans.description).to eq('Aha!')
        expect(real_trans.note).to eq('OK!')
      end
    end

    context "matching on-record transaction is manually edited" do
      it "does not copy the description and note from the not-on-record transaction to the on-record transaction" do
        account.transactions.create!(uid: 'pre_trans', amount: -100_000, datetime: 1.day.ago, on_record: false, description: 'Aha!', note: 'OK!')
        account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true, manually_edited_at: Time.now, description: 'This is fine', note: 'Thanks!')

        AccountOrganizingService.clean(account)
        real_trans = Transaction.find_by(uid: 'real_trans')

        expect(real_trans.description).to eq('This is fine')
        expect(real_trans.note).to eq('Thanks!')
      end
    end

    context "the not-on-record transaction is separated" do
      let!(:not_on_record_transaction) { account.transactions.create!(uid: 'pre_trans', amount: -100_000, datetime: 1.day.ago, on_record: false) }
      before do
        not_on_record_transaction.separating_transactions.create!(uid: 'pre_trans_s1', amount: -30_000)
        not_on_record_transaction.separating_transactions.create!(uid: 'pre_trans_s2', amount: -70_000)
      end

      context "the matching on-record transaction is not separated" do
        it "copies the separating transactions from the not-on-record to the matching on-record transaction" do
          account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true)
          real_trans = Transaction.find_by(uid: 'real_trans')
          expect(real_trans).not_to be_separated

          AccountOrganizingService.clean(account)
          real_trans = Transaction.find_by(uid: 'real_trans')
          expect(real_trans).to be_separated
          expect(real_trans.separating_transactions.count).to eq(2)
        end

        it "sets the separating transactions of the not-on-record transaction to be ignore_in_statistics" do
          account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true)

          not_on_record_transaction.separating_transactions.each do |trans|
            expect(trans).not_to be_ignore_in_statistics
          end

          AccountOrganizingService.clean(account)
          not_on_record_transaction.reload

          not_on_record_transaction.separating_transactions.each do |trans|
            expect(trans).to be_ignore_in_statistics
          end
        end
      end

      context "the matching on-record transaction is separated" do
        it "does not re-creates separating transactions" do
          account.transactions.create!(uid: 'real_trans', amount: -100_000, datetime: 1.day.ago, on_record: true)
          real_trans = Transaction.find_by(uid: 'real_trans')
          real_trans.separating_transactions.create!(uid: 'real_trans_s1', amount: -30_000)
          real_trans.separating_transactions.create!(uid: 'real_trans_s2', amount: -70_000)

          AccountOrganizingService.clean(account)
          real_trans = Transaction.find_by(uid: 'real_trans')
          expect(real_trans).to be_separated
          expect(real_trans.separating_transactions.count).to eq(2)
        end
      end
    end
  end

  describe ".merge" do
    it "copies transactions from the source account to the target account to merge them" do
      user = create(:user)
      source_account = create(:account, user: user)
      target_account = create(:account, user: user)

      source_account.transactions.create!(uid: 's_trans_1', amount: -10_000, datetime: 1.year.ago, description: 'Transaction 1')
      source_account.transactions.create!(uid: 's_trans_2', amount: -30_000, datetime: 1.year.ago, description: 'Transaction 2')
      source_account.transactions.create!(uid: 's_trans_3', amount: -100_000, datetime: 3.days.ago, description: 'Transaction 3')
      source_account.transactions.create!(uid: 's_trans_4', amount: -100_000, datetime: 1.day.ago, description: 'Transaction 4')
      s_trans = source_account.transactions.create!(uid: 's_trans_s', amount: -1_000_000, datetime: 1.day.ago, description: 'A separated transaction')
      s_trans.separating_transactions.create!(uid: 's_trans_s_1', amount: -700_000, description: 'A separating transaction 1')
      s_trans.separating_transactions.create!(uid: 's_trans_s_2', amount: -300_000, description: 'A separating transaction 2')
      source_account.transactions.create!(uid: 's_trans_5', amount: -1_000, datetime: 1.hour.ago, description: 'Transaction 5')
      s_trans.reload
      source_account.reload
      expect(source_account.balance).to eq(-1_241_000)

      target_account.transactions.create!(uid: 't_trans_1', amount: -10_000, datetime: 1.year.ago)
      target_account.transactions.create!(uid: 't_trans_2', amount: -30_000, datetime: 1.year.ago)
      target_account.transactions.create!(uid: 't_trans_3', amount: -100_000, datetime: 3.days.ago)
      target_account.transactions.create!(uid: 't_trans_4', amount: -100_000, datetime: 1.day.ago)
      target_account.transactions.create!(uid: 't_trans_s', amount: -1_000_000, datetime: 1.day.ago)
      target_account.reload
      expect(target_account.balance).to eq(-1_240_000)

      AccountOrganizingService.merge(source_account, target_account)

      target_account.reload
      expect(target_account.balance).to eq(-1_240_000)
      expect(target_account.transactions.count).to eq(15)
      t_trans_1 = Transaction.find_by(uid: 't_trans_1')
      t_trans_2 = Transaction.find_by(uid: 't_trans_2')
      t_trans_3 = Transaction.find_by(uid: 't_trans_3')
      t_trans_4 = Transaction.find_by(uid: 't_trans_4')
      t_trans_s = Transaction.find_by(uid: 't_trans_s')
      expect(t_trans_1.description).to eq('Transaction 1')
      expect(t_trans_2.description).to eq('Transaction 2')
      expect(t_trans_3.description).to eq('Transaction 3')
      expect(t_trans_4.description).to eq('Transaction 4')
      expect(t_trans_s).to be_separated
      expect(t_trans_s.separating_transactions.count).to eq(2)
      expect(t_trans_1.not_on_record_copies.first).to be_ignore_in_statistics
      expect(t_trans_2.not_on_record_copies.first).to be_ignore_in_statistics
      expect(t_trans_3.not_on_record_copies.first).to be_ignore_in_statistics
      expect(t_trans_4.not_on_record_copies.first).to be_ignore_in_statistics
      expect(t_trans_s.not_on_record_copies.first.separating_transactions.first).to be_ignore_in_statistics
    end
  end
end
