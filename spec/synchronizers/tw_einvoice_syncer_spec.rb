require 'rails_helper'

RSpec.describe TWEInvoiceSyncer, type: :model do
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:passcode_1) }
  it { is_expected.to validate_presence_of(:passcode_2) }
  it { is_expected.not_to validate_presence_of(:passcode_3) }
  it { is_expected.not_to validate_presence_of(:passcode_4) }

  it "should validate that :passcode_1 is a format of mobile number" do
    PasscodeEncryptingService.disable_decrypt_mode = true
    is_expected.to allow_value('0900000000', '0987654321').for(:passcode_1)
    is_expected.not_to allow_value('1234', '0000000000').for(:passcode_1)
    PasscodeEncryptingService.disable_decrypt_mode = false
  end

  describe "#run_collect", integration: true do
    context "with incorrect passcodes" do
      let(:syncer) { TWEInvoiceSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer With Incorrect Passcodes', passcode_1: '0900000000', passcode_2: 'something_wrong') }

      it "throws a ServiceAuthenticationError and sets the status to bad_passcode" do
        expect { syncer.run_collect }.to raise_error(Synchronizer::ServiceAuthenticationError)
        expect(syncer.status).to eq('bad_passcode')
      end
    end
  end

  describe "#run_organize" do
    let(:syncer) { TWEInvoiceSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer', passcode_1: '0900000000', passcode_2: 'some_passcode') }

    it "creates account identifiers for each possible account" do
      create_sample_parsed_data(syncer)

      syncer.run_organize
      user.reload

      expect(user.account_identifiers.count).to eq(2)
      account_identifier_1 = user.account_identifiers.find_by(type: 'tw_eazycard', identifier: '000001')
      account_identifier_2 = user.account_identifiers.find_by(type: 'tw_einvoice_general_carrier', identifier: '000001')
      expect(account_identifier_1).not_to be_identified
      expect(account_identifier_1.sample_transaction_description).to eq('白蘿蔔 × 1')
      expect(account_identifier_2).not_to be_identified
      expect(account_identifier_2.sample_transaction_description).to eq('9789863208563 無印良品的設計 × 1')
    end

    context "account identifiers settled" do
      let(:wallet) { create(:account, user: user, uid: 'wallet', name: '皮夾') }
      let(:tw_eazycard_account) { create(:account, user: user, uid: 'tw_eazycard_account', name: '悠遊卡') }
      before do
        user.account_identifiers.create!(type: 'tw_eazycard', identifier: '000001', account_uid: tw_eazycard_account.uid)
        user.account_identifiers.create!(type: 'tw_einvoice_general_carrier', identifier: '000001', account_uid: wallet.uid)
      end

      it "creates transactions in the known accounts" do
        create_sample_parsed_data(syncer)

        syncer.run_organize
        user.reload

        wallet = user.accounts.find_by(uid: 'wallet')
        expect(wallet.transactions.not_virtual.count).to eq(2)
        expect(wallet.transactions.for_statistics.count).to eq(7)
        expect(wallet.transactions.where(category_code: 'discounts').count).to eq(2)
        expect(wallet.transactions.count).to eq(9)

        tw_eazycard_account = user.accounts.find_by(uid: 'tw_eazycard_account')
        expect(tw_eazycard_account.transactions.not_virtual.count).to eq(2)
        expect(tw_eazycard_account.transactions.virtual.count).to eq(17)
      end

      context "some transactions are already created in the account" do
        let!(:books_transaction) { wallet.transactions.create!(amount: -1237000, datetime: '2016-02-10T12:00:00.000+08:00', note: '餘額：NT$ 5000', uid: SecureRandom.uuid) }
        let!(:oil_transaction) { wallet.transactions.create!(amount: -500000, datetime: '2016-02-01T20:00:00.000+08:00', description: '幫公司車加油', note: '要報帳', manually_edited: true, uid: SecureRandom.uuid) }

        it "updates the existing transactions" do
          expect(books_transaction).not_to be_separated
          expect(oil_transaction).not_to be_separated
          expect(books_transaction.description).to be_blank

          create_sample_parsed_data(syncer, count: 2)
          syncer.run_organize
          books_transaction.reload
          oil_transaction.reload

          expect(books_transaction).to be_separated
          expect(books_transaction.description).not_to be_blank
          expect(books_transaction.note).to include('餘額：NT$ 5000')
          expect(books_transaction.note).to include('發票號碼')
          expect(oil_transaction).not_to be_separated
          expect(oil_transaction.note).to include('要報帳')
          expect(oil_transaction.note).to include('發票號碼')
          expect(oil_transaction.note).to include('B00001')
          expect(oil_transaction.note).to include('９２無鉛汽油')
        end
      end
    end
  end

  def create_sample_parsed_data(syncer, count: 4)
    syncer.parsed_data.create! uid: "#{syncer.uid}-B00002", raw_data: "{\"account_type\":\"tw_einvoice_general_carrier\",\"account_code\":\"000001\",\"invoice_code\":\"B00002\",\"seller_name\":\"博客來數位科股份有限公司 96922355\",\"amount\":1237000,\"datetime\":\"2016-02-10T00:00:00.000+08:00\",\"details\":[{\"number\":0,\"name\":\"9789863208563 無印良品的設計\",\"count\":1,\"price\":284000,\"amount\":284000},{\"number\":1,\"name\":\"9789868711235W abi-Sabi：給設計者、生活家的日式美學基礎\",\"count\":1,\"price\":198000,\"amount\":198000},{\"number\":2,\"name\":\"9789862354827 設計師的材料學：創意×實驗×未來性，從原始材料到創新材質的112個設計革\",\"count\":1,\"price\":474000,\"amount\":474000},{\"number\":3,\"name\":\"9789865657581 好LOGO，如何想？如何做？：品牌的設計必修課！做出讓人一眼愛上、再看記\",\"count\":1,\"price\":300000,\"amount\":300000},{\"number\":4,\"name\":\"ACC0000001S_DISCOUNT(購物折抵金)\",\"count\":1,\"price\":-19000,\"amount\":-19000}]}"
    return if count == 1
    syncer.parsed_data.create! uid: "#{syncer.uid}-B00001", raw_data: "{\"account_type\":\"tw_einvoice_general_carrier\",\"account_code\":\"000001\",\"invoice_code\":\"B00001\",\"seller_name\":\"台灣中油股份有限公司\",\"amount\":500000,\"datetime\":\"2016-02-01T00:00:00.000+08:00\",\"details\":[{\"number\":0,\"name\":\"９２無鉛汽油\",\"count\":2,\"price\":21000,\"amount\":52000},{\"number\":1,\"name\":\"９２無鉛汽油折抵額\",\"count\":2,\"price\":-1000,\"amount\":-2000}]}"
    return if count == 2
    syncer.parsed_data.create! uid: "#{syncer.uid}-A00002", raw_data: "{\"account_type\":\"tw_eazycard\",\"account_code\":\"000001\",\"invoice_code\":\"A00002\",\"seller_name\":\"7-ELEVEN\",\"amount\":60000,\"datetime\":\"2016-02-01T00:00:00.000+08:00\",\"details\":[{\"number\":0,\"name\":\"白蘿蔔\",\"count\":1,\"price\":12000,\"amount\":12000},{\"number\":1,\"name\":\"爆汁魷魚球\",\"count\":1,\"price\":15000,\"amount\":15000},{\"number\":2,\"name\":\"菠菜蛋糕 (玉子燒)\",\"count\":1,\"price\":15000,\"amount\":15000},{\"number\":3,\"name\":\"桂冠椒香肉捲\",\"count\":1,\"price\":15000,\"amount\":15000},{\"number\":4,\"name\":\"香蔥肉捲\",\"count\":1,\"price\":15000,\"amount\":15000},{\"number\":5,\"name\":\"關東煮買 4 送 1\",\"count\":1,\"price\":-12000,\"amount\":-12000}]}"
    return if count == 3
    syncer.parsed_data.create! uid: "#{syncer.uid}-A00001", raw_data: "{\"account_type\":\"tw_eazycard\",\"account_code\":\"000001\",\"invoice_code\":\"A00001\",\"seller_name\":\"FamilyMart 全家便利商店\",\"amount\":135000,\"datetime\":\"2016-01-28T00:00:00.000+08:00\",\"details\":[{\"number\":0,\"name\":\"醬燒雞肉三明治\",\"count\":1,\"price\":35000,\"amount\":35000},{\"number\":1,\"name\":\"鮮食促\",\"count\":1,\"price\":0,\"amount\":-6000},{\"number\":2,\"name\":\"鮮採蕃茄火腿三明治\",\"count\":1,\"price\":35000,\"amount\":35000},{\"number\":3,\"name\":\"鮮食促\",\"count\":1,\"price\":0,\"amount\":-6000},{\"number\":4,\"name\":\"玄米抹茶\",\"count\":1,\"price\":23000,\"amount\":23000},{\"number\":5,\"name\":\"立頓原味奶茶\",\"count\":1,\"price\":25000,\"amount\":25000},{\"number\":6,\"name\":\"可口可樂ＰＥＴ\",\"count\":1,\"price\":29000,\"amount\":29000},{\"number\":7,\"name\":\"鮮食促\",\"count\":1,\"price\":0,\"amount\":6000},{\"number\":8,\"name\":\"鮮食促\",\"count\":1,\"price\":0,\"amount\":6000},{\"number\":9,\"name\":\"鮮食促\",\"count\":2,\"price\":0,\"amount\":-12000},{\"number\":10,\"name\":\"集點貼紙\",\"count\":1,\"price\":0,\"amount\":0}]}"
  end
end
