require 'rails_helper'

RSpec.describe NotOnRecordTransaction, type: :model do
  it { is_expected.to belong_to(:record_transaction) }

  describe "instance" do
    subject(:transaction) { create(:not_on_record_transaction) }

    context "the on-record transaction is set" do
      before do
        transaction.record_transaction = create(:transaction, account: transaction.account)
        transaction.save
      end

      its(:ignore_in_statistics) { is_expected.to eq(true) }
    end
  end
end
