require 'rails_helper'

RSpec.describe CathayUnitedBankSyncer, type: :model do
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:passcode_1) }
  it { is_expected.to validate_presence_of(:passcode_2) }
  it { is_expected.to validate_presence_of(:passcode_3) }
  it { is_expected.not_to validate_presence_of(:passcode_4) }

  it "should validate that :passcode_1 is a format of 身分證字號" do
    PasscodeEncryptingService.disable_decrypt_mode = true
    is_expected.to allow_value('A000000000', 'E123456789').for(:passcode_1)
    is_expected.not_to allow_value('1234567890', 'A1234').for(:passcode_1)
    PasscodeEncryptingService.disable_decrypt_mode = false
  end

  it "should validate that :passcode_2 is a format of 4 位阿拉伯數字" do
    PasscodeEncryptingService.disable_decrypt_mode = true
    is_expected.to allow_value('3827', '5837').for(:passcode_2)
    is_expected.not_to allow_value('37232', 'a837').for(:passcode_2)
    PasscodeEncryptingService.disable_decrypt_mode = false
  end

  it "should validate that :passcode_3 is a format of 6~12 位英數字混合" do
    PasscodeEncryptingService.disable_decrypt_mode = true
    is_expected.to allow_value('abdu38', 'fog383', 'dk26938bj381').for(:passcode_3)
    is_expected.not_to allow_value('abc12', 'dj49fjw43874iu3s8d').for(:passcode_3)
    PasscodeEncryptingService.disable_decrypt_mode = false
  end

  describe "#run_collect", integration: true do
    context "with incorrect passcodes" do
      let(:syncer) { CathayUnitedBankSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer With Incorrect Passcodes', passcode_1: 'A123456789', passcode_2: '1234', passcode_3: 'wrong1234') }

      it "throws a ServiceAuthenticationError and sets the status to bad_passcode" do
        expect { syncer.run_collect }.to raise_error(Synchronizer::ServiceAuthenticationError)
        expect(syncer.status).to eq('bad_passcode')
      end
    end
  end

  describe "#run_parse", preserve_db: true do
    before(:all) do
      @syncer = CathayUnitedBankSyncer.create!(uid: 'test_syncer', user: create(:user), name: 'Test Syncer', passcode_1: 'A123456789', passcode_2: '1234', passcode_3: 'abcd1234')
      create_sample_collected_pages(@syncer)
      @syncer.run_parse
    end
    let(:syncer) { @syncer }

    it "sets the syncer status to parsed" do
      expect(syncer.status).to eq('parsed')
    end

    it "parses account data" do
      expect(syncer.parsed_data.where(attribute_1: 'account').count).to eq(3)
      sample_account_data = syncer.parsed_data.find_by('attribute_1 = ? AND attribute_2 LIKE ?', 'account', '%999900000000%')
      expect(sample_account_data.data[:num]).to eq('999900000000')
      expect(sample_account_data.data[:type_desc]).to eq('KOKO儲值支付帳戶-第三類')
      expect(sample_account_data.data[:balance]).to eq(50)
      sample_account_data = syncer.parsed_data.find_by('attribute_1 = ? AND attribute_2 LIKE ?', 'account', '%777700000000%')
      expect(sample_account_data.data[:num]).to eq('777700000000')
      expect(sample_account_data.data[:type_desc]).to eq('活期儲蓄存款')
      expect(sample_account_data.data[:balance]).to eq(23_780)
    end

    it "parses transaction data" do
      expect(syncer.parsed_data.where(attribute_1: 'transaction').count).to eq(14)
    end

    it "marks the parsed collected_pages as parsed" do
      syncer.collected_pages.each do |collected_page|
        expect(collected_page.parsed_at).not_to be_blank
      end
    end

    it "is rerunnable" do
      syncer.collected_pages.each do |collected_page|
        collected_page.update_attributes(parsed_at: nil)
      end

      syncer.run_parse

      expect(syncer.parsed_data.where(attribute_1: 'account').count).to eq(3)
      expect(syncer.parsed_data.where(attribute_1: 'transaction').count).to eq(14)
    end
  end

  describe "#run_organize", preserve_db: true do
    before(:all) do
      @syncer = CathayUnitedBankSyncer.create!(uid: 'test_organize_syncer', user: create(:user), name: 'Test Syncer', passcode_1: 'A123456789', passcode_2: '1234', passcode_3: 'abcd1234')
      account = @syncer.accounts.create!(uid: "#{@syncer.user_id}-cathay_united_bank-777700000000-#{@syncer.uid}", name: '我的帳戶')
      t = account.transactions.create!(uid: SecureRandom.uuid, datetime: '2015/01/08', amount: -200_000, description: "App Store 購買")
      t.separating_transactions.create!(uid: SecureRandom.uuid, datetime: '2015/01/08', amount: -180_000, description: "A App")
      t.separating_transactions.create!(uid: SecureRandom.uuid, datetime: '2015/01/08', amount: -20_000, description: "A Purchase")
      create_sample_parsed_data(@syncer)
      @syncer.run_organize
    end
    let(:syncer) { @syncer }

    it "sets the syncer status to synced" do
      expect(syncer.status).to eq('synced')
    end

    it "manages accounts" do
      expect(Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}").balance).to eq(23_780_000)
      expect(Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-888800000000-#{syncer.uid}").balance).to eq(0)
      expect(Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-999900000000-#{syncer.uid}").balance).to eq(50_000)
      expect(Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}").name).to eq('我的帳戶')
    end

    it "creates transactions" do
      sample_account = Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-999900000000-#{syncer.uid}")
      expect(sample_account.transactions.on_record.count).to eq(2)
      expect(sample_account.transactions.order(datetime: :asc).first.description).to eq('網銀轉帳－張牧之 0000099***999999')
    end

    it "deals with pre-created not-on-record transactions" do
      sample_account = Account.find_by(uid: "#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}")
      expect(sample_account.transactions.not_on_record.count).to eq(1)
      expect(sample_account.transactions.not_on_record_copy.count).to eq(1)
      expect(sample_account.transactions.virtual.count).to eq(4)
      sample_transaction_datetime = DateTime.parse('2015/01/08')
      sample_transaction = sample_account.transactions.on_record.find_by(amount: -200_000, datetime: (sample_transaction_datetime - 1.day)..(sample_transaction_datetime + 1.day))
      expect(sample_transaction.description).to eq('App Store 購買')
      expect(sample_transaction.separated).to eq(true)
      expect(sample_transaction.separating_transactions.count).to eq(2)
    end
  end

  def create_sample_collected_pages(syncer)
    # 帳號：999900000000，一筆網銀轉入與一筆網銀轉出
    syncer.collected_pages.create! attribute_1: "999900000000", attribute_2: "KOKO儲值支付帳戶-第三類", body: "\n<table class=\"tDefault\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\"><thead><tr><td width=\"16%\">日期</td><td width=\"17%\">提出</td><td width=\"17%\">存入</td><td width=\"17%\">餘額</td><td width=\"12%\">說明</td><td width=\"21%\">備註<br>特別備註</td></tr></thead><tbody><tr><td data-title=\"日期\">2015/01/01</td><td class=\"textR\" data-title=\"提出\">&nbsp;</td><td class=\"textR\" data-title=\"存入\">100</td><td class=\"textR\" data-title=\"餘額\">100</td><td data-title=\"說明\">網銀轉帳</td><td data-title=\"備註 / 特別備註\">張牧之<br>0000099***999999</td></tr><tr class=\"even-ie\"><td data-title=\"日期\">2015/01/02</td><td class=\"textR\" data-title=\"提出\">50</td><td class=\"textR\" data-title=\"存入\">&nbsp;</td><td class=\"textR\" data-title=\"餘額\">50</td><td data-title=\"說明\">網銀轉帳</td><td data-title=\"備註 / 特別備註\">馬邦德<br>0000088***888888</td></tr></tbody></table>\n"
    # 帳號：888800000000，無紀錄
    syncer.collected_pages.create! attribute_1: "888800000000", attribute_2: "LINE儲值支付帳戶-第三類", body: "\n<table class=\"tDefault\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\"><thead><tr><td></td></tr></thead><tbody><tr class=\"GridEmpty\"><td class=\"red\">查無資料</td></tr></tbody></table>\n"
    # 帳號：777700000000，12 筆紀錄
    syncer.collected_pages.create! attribute_1: "777700000000", attribute_2: "活期儲蓄存款", body: <<-EOF.strip_heredoc
      <table cellpadding="0" cellspacing="0" class="tDefault" width="100%">
          <thead>
              <tr>
                  <td width="16%">日期</td>
                  <td width="17%">提出</td>
                  <td width="17%">存入</td>
                  <td width="17%">餘額</td>
                  <td width="12%">說明</td>
                  <td width="21%">備註<br>
                  特別備註</td>
              </tr>
          </thead>
          <tbody>
              <tr>
                  <td data-title="日期">2015/01/01</td>
                  <td class="textR" data-title="提出">1,000</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">9,000</td>
                  <td data-title="說明">自行提款</td>
                  <td data-title="備註 / 特別備註">0130VE69<br></td>
              </tr>
              <tr class="even-ie">
                  <td data-title="日期">2015/01/02</td>
                  <td class="textR" data-title="提出">500</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">8,500</td>
                  <td data-title="說明">ｉ消費</td>
                  <td data-title="備註 / 特別備註">悠遊加值－<br></td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/03</td>
                  <td class="textR" data-title="提出">100</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">8,400</td>
                  <td data-title="說明">ｉ消費</td>
                  <td data-title="備註 / 特別備註">中油<br></td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/04</td>
                  <td class="textR" data-title="提出">200</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">8,200</td>
                  <td data-title="說明">ｉ消費</td>
                  <td data-title="備註 / 特別備註">Uber BV<br></td>
              </tr>
              <tr class="even-ie">
                  <td data-title="日期">2015/01/04</td>
                  <td class="textR" data-title="提出">10</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">8,190</td>
                  <td data-title="說明">ｉ費用</td>
                  <td data-title="備註 / 特別備註">國外交易手<br></td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/05</td>
                  <td class="textR" data-title="提出">5,000</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">3,190</td>
                  <td data-title="說明">跨行提款</td>
                  <td data-title="備註 / 特別備註">0000000000<br></td>
              </tr>
              <tr class="even-ie">
                  <td data-title="日期">2015/01/06</td>
                  <td class="textR" data-title="提出">5</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">3,185</td>
                  <td data-title="說明">跨行費用</td>
                  <td data-title="備註 / 特別備註"><br></td>
              </tr>
              <tr class="even-ie">
                  <td data-title="日期">2015/01/07</td>
                  <td class="textR" data-title="提出">1,185</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">2,000</td>
                  <td data-title="說明">ｉ消費</td>
                  <td data-title="備註 / 特別備註">高鐵ＥＣ<br></td>
              </tr>
              <tr class="even-ie">
                  <td data-title="日期">2015/01/08</td>
                  <td class="textR" data-title="提出">200</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">1,800</td>
                  <td data-title="說明">ｉ消費</td>
                  <td data-title="備註 / 特別備註">ITUNES.COM/B<br></td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/08</td>
                  <td class="textR" data-title="提出">20</td>
                  <td class="textR" data-title="存入">&nbsp;</td>
                  <td class="textR" data-title="餘額">1,780</td>
                  <td data-title="說明">ｉ費用</td>
                  <td data-title="備註 / 特別備註">國外交易手<br></td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/09</td>
                  <td class="textR" data-title="提出">&nbsp;</td>
                  <td class="textR" data-title="存入">2,000</td>
                  <td class="textR" data-title="餘額">3,780</td>
                  <td data-title="說明">跨行轉入</td>
                  <td data-title="備註 / 特別備註"><br>
                  0000111***111111</td>
              </tr>
              <tr>
                  <td data-title="日期">2015/01/10</td>
                  <td class="textR" data-title="提出">&nbsp;</td>
                  <td class="textR" data-title="存入">20,000</td>
                  <td class="textR" data-title="餘額">23,780</td>
                  <td data-title="說明">金融卡存</td>
                  <td data-title="備註 / 特別備註"><br>
                  AAAAA</td>
              </tr>
          </tbody>
      </table>
    EOF
  end

  def create_sample_parsed_data(syncer)
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-01-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-01-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-01-0-#{syncer.uid}",
          "account": "999900000000",
          "date": "2015/01/01",
          "amount": 100,
          "balance": 100,
          "explanation": "網銀轉帳",
          "note": "張牧之\\n0000099***999999"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-02-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-02-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-999900000000-2015-01-02-0-#{syncer.uid}",
          "account": "999900000000",
          "date": "2015/01/02",
          "amount": -50,
          "balance": 50,
          "explanation": "網銀轉帳",
          "note": "馬邦德\\n0000088***888888"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "account-#{syncer.user_id}-cathay_united_bank-999900000000-#{syncer.uid}",
      attribute_1: 'account',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-999900000000-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-999900000000-#{syncer.uid}",
          "num": "999900000000",
          "balance": 50,
          "type_desc": "KOKO儲值支付帳戶-第三類"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "account-#{syncer.user_id}-cathay_united_bank-888800000000-#{syncer.uid}",
      attribute_1: 'account',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-888800000000-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-888800000000-#{syncer.uid}",
          "num": "888800000000",
          "balance": 0,
          "type_desc": "LINE儲值支付帳戶-第三類"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-01-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-01-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-01-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/01",
          "amount": -1000,
          "balance": 9000,
          "explanation": "自行提款",
          "note": "0130VE69\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-02-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-02-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-02-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/02",
          "amount": -500,
          "balance": 8500,
          "explanation": "ｉ消費",
          "note": "悠遊加值－\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-03-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-03-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-03-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/03",
          "amount": -100,
          "balance": 8400,
          "explanation": "ｉ消費",
          "note": "中油\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/04",
          "amount": -200,
          "balance": 8200,
          "explanation": "ｉ消費",
          "note": "Uber BV\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-1-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-1-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-04-1-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/04",
          "amount": -10,
          "balance": 8190,
          "explanation": "ｉ費用",
          "note": "國外交易手\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-05-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-05-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-05-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/05",
          "amount": -5000,
          "balance": 3190,
          "explanation": "跨行提款",
          "note": "0000000000\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-06-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-06-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-06-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/06",
          "amount": -5,
          "balance": 3185,
          "explanation": "跨行費用",
          "note": "\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-07-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-07-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-07-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/07",
          "amount": -1185,
          "balance": 2000,
          "explanation": "ｉ消費",
          "note": "高鐵ＥＣ\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/08",
          "amount": -200,
          "balance": 1800,
          "explanation": "ｉ消費",
          "note": "ITUNES.COM/B\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-1-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-1-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-08-1-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/08",
          "amount": -20,
          "balance": 1780,
          "explanation": "ｉ費用",
          "note": "國外交易手\\n"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-09-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-09-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-09-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/09",
          "amount": 2000,
          "balance": 3780,
          "explanation": "跨行轉入",
          "note": "\\n\\n            0000111***111111"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "transaction-#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-10-0-#{syncer.uid}",
      attribute_1: 'transaction',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-10-0-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-2015-01-10-0-#{syncer.uid}",
          "account": "777700000000",
          "date": "2015/01/10",
          "amount": 20000,
          "balance": 23780,
          "explanation": "金融卡存",
          "note": "\\n\\n            AAAAA"
        }
      EOF
    )
    syncer.parsed_data.create!(
      uid: "account-#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}",
      attribute_1: 'account',
      attribute_2: "#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}",
      raw_data: <<-EOF.strip_heredoc
        {
          "uid": "#{syncer.user_id}-cathay_united_bank-777700000000-#{syncer.uid}",
          "num": "777700000000",
          "balance": 23780,
          "type_desc": "活期儲蓄存款"
        }
      EOF
    )
  end
end
