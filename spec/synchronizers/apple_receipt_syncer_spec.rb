require 'rails_helper'

RSpec.describe AppleReceiptSyncer, type: :model do
  describe "#run_parse", preserve_db: true do
    before(:all) do
      @syncer = AppleReceiptSyncer.create!(uid: SecureRandom.uuid, user: create(:user), name: 'Test Syncer')
      create_sample_collected_pages(@syncer)
      @syncer.run_parse
    end
    let(:syncer) { @syncer }

    it "sets the syncer status to parsed" do
      expect(syncer.status).to eq('parsed')
    end

    it "parses data from emails" do
      expect(syncer.parsed_data.count).to eq(1)
      data = syncer.parsed_data.last.data
      expect(data[:apple_id]).to eq('xxxxxxxx@gmail.com')
      expect(data[:paid_with]).to eq(['visa', '9999'])
      expect(data[:amount]).to eq(830_000)
      expect(data[:date]).to eq('2015/01/01')
      expect(data[:order_id]).to eq('AAAAA111111')
      expect(data[:store_orders].map { |i| i[:store_name] }).to eq(['iTunes Store', 'iCloud', 'Mac App Store', 'App Store'])
      expect(data[:store_orders][0][:items][0][:image_url]).to start_with('http')
      expect(data[:store_orders][0][:items][0][:name]).to eq('傷心的人別聽慢歌 (貫徹快樂)')
      expect(data[:store_orders][1][:items][0][:type]).to eq('iCloud 儲存空間')
      expect(data[:store_orders][2][:items][0][:bought_from]).to eq('Mac')
      expect(data[:store_orders][3][:items][0][:provide_by]).to eq('THIX')
      expect(data[:store_orders][3][:items][1][:price]).to eq(90_000)
      expect(data[:store_orders][3][:items][2][:provide_by]).to eq('')
    end

    it "skips the same email" do
      create_sample_collected_pages(syncer)
      syncer.run_parse
      expect(syncer.collected_pages.where.not(skipped_at: nil).count).to eq(1)
      expect(syncer.parsed_data.count).to eq(1)
    end
  end

  describe "#run_organize" do
    let(:user) { create(:user) }
    let(:syncer) { AppleReceiptSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer') }
    subject { create_sample_parsed_data(syncer); syncer.run_organize }

    it "creates account identifiers for possible accounts" do
      subject
      expect(user.account_identifiers.where(type: 'visa').last.identifier).to eq('9999')
    end

    context "account identifiers settled" do
      let(:visa_card) { create(:account, user: user, uid: 'visa_card', name: 'My Visa Card') }
      before do
        user.account_identifiers.create!(type: 'visa', identifier: '9999', account_uid: visa_card.uid)
      end

      it "creates transactions in the account" do
        subject

        expect(visa_card.transactions.not_virtual.count).to eq(2)
        expect(visa_card.transactions.for_statistics.count).to eq(9)
        expect(visa_card.transactions.count).to eq(11)
        expect(visa_card.transactions.last.datetime.year).to eq(2015)
      end

      it "sets the parsed_data to be organized" do
        subject

        expect(syncer.parsed_data.last.organized_at).not_to be_blank
      end

      it "is rerunnable" do
        subject

        syncer.run_organize(level: :complete)

        expect(visa_card.transactions.not_virtual.count).to eq(2)
        expect(visa_card.transactions.for_statistics.count).to eq(9)
        expect(visa_card.transactions.count).to eq(11)
        expect(visa_card.transactions.last.datetime.year).to eq(2015)
      end

      context "some transactions are already created in the account" do
        let(:app_store_transaction) { visa_card.transactions.create!(amount: -830_000, datetime: '2015/01/01', uid: SecureRandom.uuid) }

        it "updates the existing transactions" do
          expect(app_store_transaction).not_to be_separated

          subject
          app_store_transaction.reload

          expect(app_store_transaction).to be_separated
        end
      end
    end
  end

  def create_sample_collected_pages(syncer)
    syncer.collected_pages.create! attribute_1: 'email', body: <<-EOF
      <div style="margin:0;padding:0">
        <table align="center" border="0" cellpadding="0" cellspacing="0" style=
        "border-collapse:collapse;border-spacing:0">
          <tbody>
            <tr>
              <td valign="top">
                <div style=
                "display:block;padding:0;margin:0;min-height:100%;max-height:none;min-height:none;line-height:normal;overflow:visible">
                  <table align="center" border="0" cellpadding="0" cellspacing="0"
                  style="border-collapse:collapse;border-spacing:0" width="740">
                    <tbody>
                      <tr>
                        <td width="40"></td>
                        <td align="left"><img alt="Apple" border="0" height="42"
                        src=
                        "http://r.mzstatic.com/email/images_shared/logo_apple_d-2x.png"
                        style="border:none;padding:0;margin:0" width="42"></td>
                        <td align="right" style=
                        "font-size:32px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif;color:rgb(153,153,153)">
                        收據</td>
                        <td width="40"></td>
                      </tr>
                      <tr>
                        <td colspan="4"></td>
                      </tr>
                      <tr>
                        <td></td>
                      </tr>
                      <tr>
                        <td align="center" colspan="4">
                          <table border="0" cellpadding="0" cellspacing="0"
                          style="border-collapse:collapse;border-spacing:0"
                          width="660">
                            <tbody>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing=
                                  "0" style=
                                  "border-collapse:collapse;border-spacing:0;color:rgb(51,51,51);background-color:rgb(245,245,245);border-radius:3px;font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif">
                                  <tbody>
                                      <tr>
                                        <td colspan="2" style=
                                        "padding-left:20px;border-style:solid;border-color:white;border-left-width:0px;border-right-width:1px;border-bottom-width:1px;border-top-width:0px"
                                        width="320">
                                          <span style=
                                          "color:rgb(153,153,153);font-size:10px">
                                          Apple ID</span><br>
                                          <a href="mailto:xxxxxxxx@gmail.com"
                                          target=
                                          "_blank">xxxxxxxx@gmail.com</a>
                                        </td>
                                        <td rowspan="3" style=
                                        "padding-left:20px;border-style:solid;border-color:white;border-left-width:0px;border-right-width:0px;border-bottom-width:0px;border-top-width:0px"
                                        width="220"><span style=
                                        "color:rgb(153,153,153);font-size:10px">帳單寄給</span><br>

                                        VISA .... 9999<br>
                                        X XX<br>
                                        XXXXXXXXXXXX<br>
                                        XXXXXXX<br>
                                        XXXXXXXX XXXXX, XXXXXXX<br>
                                        XXX</td>
                                        <td align="right" rowspan="3" style=
                                        "padding-right:20px;border-style:solid;border-color:white;border-left-width:1px;border-right-width:0px;border-bottom-width:0px;border-top-width:0px"
                                        width="120"><span style=
                                        "color:rgb(153,153,153);font-size:10px">總計</span><br>

                                        <span style=
                                        "font-size:16px;font-weight:bold">NT$
                                        830</span></td>
                                      </tr>
                                      <tr>
                                        <td colspan="2" style=
                                        "padding-left:20px;border-style:solid;border-color:white;border-left-width:0px;border-right-width:1px;border-bottom-width:1px;border-top-width:0px">
                                        <span style=
                                        "color:rgb(153,153,153);font-size:10px">日期</span><br>

                                        2015年01月01日</td>
                                      </tr>
                                      <tr>
                                        <td style=
                                        "padding-left:20px;border-style:solid;border-color:white;border-left-width:0px;border-right-width:1px;border-bottom-width:0px;border-top-width:0px">
                                        <span style=
                                        "color:rgb(153,153,153);font-size:10px">訂單
                                        ID</span><br>
                                        <span style="color:#0073ff"><a href=
                                        ""
                                        target=
                                        "_blank">AAAAA111111</a></span></td>
                                        <td style=
                                        "padding-left:20px;border-style:solid;border-color:white;border-left-width:0px;border-right-width:1px;border-bottom-width:0px;border-top-width:0px">
                                        <span style=
                                        "color:rgb(153,153,153);font-size:10px">文件編號</span><br>

                                        1111111100000000</td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                              <tr>
                                <td></td>
                              </tr>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing="0" style=
                                  "border-collapse:collapse;border-spacing:0;width:660px;color:rgb(51,51,51);font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif"
                                  width="660">
                                    <tbody>
                                      <tr style="background-color:rgb(245,245,245)">
                                        <td colspan="2" style=
                                        "width:350px;padding-left:10px;border-top-left-radius:3px;border-bottom-left-radius:3px"
                                        width="350"><span style="font-size:14px;font-weight:500">iTunes
                                        Store</span></td>
                                        <td style="width:100px;padding-left:20px" width="100">
                                        <span style="color:rgb(153,153,153);font-size:10px">類型</span></td>
                                        <td style="width:120px;padding-left:20px" width="120">
                                        <span style="color:rgb(153,153,153);font-size:10px">購自</span></td>
                                        <td align="right" style=
                                        "width:100px;padding-right:20px;border-top-right-radius:3px;border-bottom-right-radius:3px"
                                        width="90"><span style=
                                        "color:rgb(153,153,153);font-size:10px;white-space:nowrap">價格</span></td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px" width="60">
                                        <img alt="傷心的人別聽慢歌 (貫徹快樂)" border="0" height="60" src=
                                        "http://a1895.phobos.apple.com/us/r30/Music2/v4/80/b3/5a/80b35a06-64f3-ea29-51af-83ae5f1cc649/cover136x136.jpeg"
                                        style="border:none;padding:0;margin:0" width="60"></td>
                                        <td style="padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style="font-weight:600">傷心的人別聽慢歌
                                        (貫徹快樂)</span><br>
                                        <span style="color:rgb(153,153,153)">五月天</span><br>
                                        <span style="font-size:10px"><a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">撰寫評論</a>&nbsp;|&nbsp;<a href=
                                        ""
                                        style="color:#0073ff" target="_blank">回報問題</a></span></td>
                                        <td style="padding:0 0 0 20px;width:100px" width="100">
                                        <span style="color:rgb(153,153,153)">歌曲</span></td>
                                        <td style="padding:0 0 0 20px;width:120px" width="120">
                                        <span style="color:rgb(153,153,153)">Mac</span></td>
                                        <td align="right" style="padding:0 20px 0 0;width:100px" width=
                                        "90"><span style="font-weight:600;white-space:nowrap">NT$
                                        20</span></td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                              <tr>
                                <td></td>
                              </tr>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing="0" style=
                                  "border-collapse:collapse;border-spacing:0;width:660px;color:rgb(51,51,51);font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif"
                                  width="660">
                                    <tbody>
                                      <tr style="background-color:rgb(245,245,245)">
                                        <td colspan="2" style=
                                        "width:350px;padding-left:10px;border-top-left-radius:3px;border-bottom-left-radius:3px"
                                        width="350"><span style=
                                        "font-size:14px;font-weight:500">iCloud</span></td>
                                        <td style="width:100px;padding-left:20px" width="100">
                                        <span style="color:rgb(153,153,153);font-size:10px">類型</span></td>
                                        <td style="width:120px;padding-left:20px" width="120">
                                        <span style="color:rgb(153,153,153);font-size:10px">購自</span></td>
                                        <td align="right" style=
                                        "width:100px;padding-right:20px;border-top-right-radius:3px;border-bottom-right-radius:3px"
                                        width="90"><span style=
                                        "color:rgb(153,153,153);font-size:10px;white-space:nowrap">價格</span></td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px" width="60">
                                        <img alt="iCloud：50 GB 儲存空間方案" border="0" height="60" src=
                                        "http://r.mzstatic.com/email/images_shared/dItemArtiCloud2x.jpg"
                                        style="border:none;padding:0;margin:0" width="60"></td>
                                        <td style="padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style="font-weight:600">iCloud：50 GB
                                        儲存空間方案</span><br>
                                        <span style=
                                        "color:rgb(153,153,153)">每月&nbsp;|&nbsp;2015年01月01日</span><br>
                                        <span style="font-size:10px"></span></td>
                                        <td style="padding:0 0 0 20px;width:100px" width="100">
                                        <span style="color:rgb(153,153,153)">iCloud 儲存空間</span></td>
                                        <td style="padding:0 0 0 20px;width:120px" width="120">
                                        <span style="color:rgb(153,153,153)"></span></td>
                                        <td align="right" style="padding:0 20px 0 0;width:100px" width=
                                        "90"><span style="font-weight:600;white-space:nowrap">NT$
                                        30</span></td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                              <tr>
                                <td></td>
                              </tr>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing="0" style=
                                  "border-collapse:collapse;border-spacing:0;width:660px;color:rgb(51,51,51);font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif"
                                  width="660">
                                    <tbody>
                                      <tr style="background-color:rgb(245,245,245)">
                                        <td colspan="2" style=
                                        "width:350px;padding-left:10px;border-top-left-radius:3px;border-bottom-left-radius:3px"
                                        width="350"><span style="font-size:14px;font-weight:500">Mac App
                                        Store</span></td>
                                        <td style="width:100px;padding-left:20px" width="100">
                                        <span style="color:rgb(153,153,153);font-size:10px">類型</span></td>
                                        <td style="width:120px;padding-left:20px" width="120">
                                        <span style="color:rgb(153,153,153);font-size:10px">購自</span></td>
                                        <td align="right" style=
                                        "width:100px;padding-right:20px;border-top-right-radius:3px;border-bottom-right-radius:3px"
                                        width="90"><span style=
                                        "color:rgb(153,153,153);font-size:10px;white-space:nowrap">價格</span></td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px" width="60">
                                        <img alt="iMovie" border="0" height="60" src=
                                        "http://a624.phobos.apple.com/us/r30/Purple5/v4/d4/d3/1f/d4d31f1b-bbe8-2e76-44ce-4a6df3f5f377/icon128.png"
                                        style="border:none;padding:0;margin:0" width="60"></td>
                                        <td style="padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style="font-weight:600">iMovie</span><br>
                                        <span style="color:rgb(153,153,153)">Apple</span><br>
                                        <span style="font-size:10px"><a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">撰寫評論</a>&nbsp;|&nbsp;<a href=
                                        ""
                                        style="color:#0073ff" target="_blank">回報問題</a></span></td>
                                        <td style="padding:0 0 0 20px;width:100px" width="100">
                                        <span style="color:rgb(153,153,153)">App</span></td>
                                        <td style="padding:0 0 0 20px;width:120px" width="120">
                                        <span style="color:rgb(153,153,153)">Mac</span></td>
                                        <td align="right" style="padding:0 20px 0 0;width:100px" width=
                                        "90"><span style="font-weight:600;white-space:nowrap">NT$
                                        450</span></td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                              <tr>
                                <td></td>
                              </tr>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing=
                                  "0" style=
                                  "border-collapse:collapse;border-spacing:0;width:660px;color:rgb(51,51,51);font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif"
                                  width="660">
                                    <tbody>
                                      <tr style=
                                      "background-color:rgb(245,245,245)">
                                        <td colspan="2" style=
                                        "width:350px;padding-left:10px;border-top-left-radius:3px;border-bottom-left-radius:3px"
                                        width="350"><span style=
                                        "font-size:14px;font-weight:500">App
                                        Store</span></td>
                                        <td style="width:100px;padding-left:20px"
                                        width="100"><span style=
                                        "color:rgb(153,153,153);font-size:10px">類型</span></td>
                                        <td style="width:120px;padding-left:20px"
                                        width="120"><span style=
                                        "color:rgb(153,153,153);font-size:10px">購自</span></td>
                                        <td align="right" style=
                                        "width:100px;padding-right:20px;border-top-right-radius:3px;border-bottom-right-radius:3px"
                                        width="90"><span style=
                                        "color:rgb(153,153,153);font-size:10px;white-space:nowrap">
                                        價格</span></td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px"
                                        width="60"><img alt="BEAKER by THIX"
                                        border="0" height="60" src=
                                        "http://is1.mzstatic.com/image/thumb/Purple69/v4/75/73/a9/7573a969-6d71-0ee3-b721-4a334d76f38b/source/120x120bb-80.jpg"
                                        style=
                                        "border:none;padding:0;margin:0;border-radius:14px;border:1px solid rgba(128,128,128,0.2)"
                                        width="60"></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style=
                                        "font-weight:600">BEAKER by
                                        THIX</span><br>
                                        <span style=
                                        "color:rgb(153,153,153)">THIX</span><br>
                                        <span style="font-size:10px"><a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">撰寫評論</a>&nbsp;|&nbsp;<a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">回報問題</a></span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:100px" width=
                                        "100"><span style=
                                        "color:rgb(153,153,153)">iOS
                                        App</span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:120px" width=
                                        "120"><span style=
                                        "color:rgb(153,153,153)">My iPhone
                                        5S</span></td>
                                        <td align="right" style=
                                        "padding:0 20px 0 0;width:100px" width=
                                        "90"><span style=
                                        "font-weight:600;white-space:nowrap">NT$
                                        90</span></td>
                                      </tr>
                                      <tr>
                                        <td colspan="5" height="1" style=
                                        "padding:0 10px 0 10px">
                                          <div style=
                                          "line-height:1px;min-height:1px;background-color:rgb(238,238,238)">
                                          </div>
                                        </td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px"
                                        width="60"><img alt="The Swords" border=
                                        "0" height="60" src=
                                        "http://is3.mzstatic.com/image/thumb/Purple69/v4/84/bf/46/84bf4660-16b4-4e8e-0322-d8187f3e92f1/source/120x120bb-80.jpg"
                                        style=
                                        "border:none;padding:0;margin:0;border-radius:14px;border:1px solid rgba(128,128,128,0.2)"
                                        width="60"></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style=
                                        "font-weight:600">The Swords</span><br>
                                        <span style=
                                        "color:rgb(153,153,153)">Lee-Kuo
                                        Chen</span><br>
                                        <span style="font-size:10px"><a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">撰寫評論</a>&nbsp;|&nbsp;<a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">回報問題</a></span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:100px" width=
                                        "100"><span style=
                                        "color:rgb(153,153,153)">iOS
                                        App</span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:120px" width=
                                        "120"><span style=
                                        "color:rgb(153,153,153)">My iPhone
                                        5S</span></td>
                                        <td align="right" style=
                                        "padding:0 20px 0 0;width:100px" width=
                                        "90"><span style=
                                        "font-weight:600;white-space:nowrap">NT$
                                        90</span></td>
                                      </tr>
                                      <tr>
                                        <td colspan="5" height="1" style=
                                        "padding:0 10px 0 10px">
                                          <div style=
                                          "line-height:1px;min-height:1px;background-color:rgb(238,238,238)">
                                          </div>
                                        </td>
                                      </tr>
                                      <tr>
                                        <td align="center" style=
                                        "padding:0 0 0 20px;margin:0;height:60px;width:60px"
                                        width="60"><img alt=
                                        "Walkr - 口袋裡的銀河冒險, 一堆能量方塊" border="0"
                                        height="60" src=
                                        "http://is1.mzstatic.com/image/thumb/Purple49/v4/7d/df/28/7ddf280c-e7a3-ca63-16d4-8f296fd73177/source/120x120bb-80.jpg"
                                        style=
                                        "border:none;padding:0;margin:0;border-radius:14px;border:1px solid rgba(128,128,128,0.2)"
                                        width="60"></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:260px;line-height:15px"
                                        width="260"><span style=
                                        "font-weight:600">Walkr - 口袋裡的銀河冒險,
                                        一堆能量方塊</span><br>
                                        <span style="font-size:10px"><a href=
                                        ""
                                        style="color:#0073ff" target=
                                        "_blank">回報問題</a></span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:100px" width=
                                        "100"><span style=
                                        "color:rgb(153,153,153)">App
                                        內購買項目</span></td>
                                        <td style=
                                        "padding:0 0 0 20px;width:120px" width=
                                        "120"><span style=
                                        "color:rgb(153,153,153)">My iPhone
                                        5S</span></td>
                                        <td align="right" style=
                                        "padding:0 20px 0 0;width:100px" width=
                                        "90"><span style=
                                        "font-weight:600;white-space:nowrap">NT$
                                        150</span></td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                              <tr>
                                <td>
                                  <table border="0" cellpadding="0" cellspacing=
                                  "0" style=
                                  "border-collapse:collapse;border-spacing:0;width:660px;color:rgb(51,51,51);font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif"
                                  width="660">
                                    <tbody>
                                      <tr>
                                        <td colspan="3" height="1" style=
                                        "padding:0 10px 0 10px">
                                          <div style=
                                          "line-height:1px;min-height:1px;background-color:rgb(238,238,238)">
                                          </div>
                                        </td>
                                      </tr>
                                      <tr>
                                        <td align="right" style=
                                        "color:rgb(153,153,153);font-size:10px;font-weight:600;padding:0 30px 0 0;border-width:1px;border-color:rgb(238,238,238)">
                                        總計</td>
                                        <td style=
                                        "background-color:rgb(238,238,238);width:1px"
                                        width="1"></td>
                                        <td align="right" style=
                                        "width:120px;padding:0 20px 0 0;font-size:16px;font-weight:600;white-space:nowrap"
                                        width="90">NT$ 830</td>
                                      </tr>
                                      <tr>
                                        <td colspan="3" height="1" style=
                                        "padding:0 10px 0 10px">
                                          <div style=
                                          "line-height:1px;min-height:1px;background-color:rgb(238,238,238)">
                                          </div>
                                        </td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </td>
                      </tr>
                      <tr>
                        <td colspan="4"></td>
                      </tr>
                      <tr>
                        <td></td>
                        <td align="center" colspan="2" style=
                        "font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif;color:rgb(153,153,153)">
                        若要瞭解如何管理 iTunes、iBooks 和 App Store 購買項目的密碼偏好設定，請前往
                        <a href="https://support.apple.com/HT204030" target=
                        "_blank">https://support.apple.com/HT204030</a>。
                        </td>
                        <td></td>
                      </tr>
                      <tr>
                        <td colspan="4"></td>
                      </tr>
                      <tr>
                        <td></td>
                        <td align="center" colspan="2" style=
                        "font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif;color:rgb(153,153,153)">
                        <img alt="" border="0" height="26" src=
                        "http://r.mzstatic.com/email/images_shared/logo_apple_small_d-2x.png"
                        style="border:none;padding:0;margin:0" width="26"></td>
                        <td></td>
                      </tr>
                      <tr>
                        <td colspan="4"></td>
                      </tr>
                      <tr>
                        <td></td>
                        <td align="center" colspan="2" style=
                        "font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif;color:rgb(153,153,153)">
                        <a href=
                        ""
                          style="color:#0073ff" target="_blank">Apple ID
                          摘要</a>&nbsp;•&nbsp;<a href=
                          ""
                          style="color:#0073ff" target=
                          "_blank">購買記錄</a><a>&nbsp;•&nbsp;</a><a href=
                          ""
                          style="color:#0073ff" target=
                          "_blank">銷售條款</a>&nbsp;•&nbsp;<a href=
                          ""
                          style="color:#0073ff" target="_blank">隱私權政策</a>
                        </td>
                        <td></td>
                      </tr>
                      <tr>
                        <td colspan="4"></td>
                      </tr>
                      <tr>
                        <td></td>
                        <td align="center" colspan="2" style=
                        "font-size:12px;font-family:&#39;Helvetica Neue&#39;,Helvetica,Arial,sans-serif;color:rgb(153,153,153)">
                        版權所有 © 2016 iTunes S.à r.l.<br>
                          <a href=
                          ""
                          style="color:#0073ff" target="_blank">保留一切權利</a>
                        </td>
                        <td></td>
                      </tr>
                      <tr>
                        <td colspan="4" height="30"></td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div>...</div>
              </td>
            </tr>
          </tbody>
        </table>
        <br>
      </div>
    EOF
  end

  def create_sample_parsed_data(syncer)
    syncer.parsed_data.create! uid: SecureRandom.uuid, raw_data: <<-EOF
      {
        "apple_id": "xxxxxxxx@gmail.com",
        "paid_with": ["visa", "9999"],
        "amount": 830000,
        "date": "2015/01/01",
        "order_id": "AAAAA111111",
        "store_orders": [{
          "store_name": "iTunes Store",
          "items": [{
            "image_url": "http://a1895.phobos.apple.com/us/r30/Music2/v4/80/b3/5a/80b35a06-64f3-ea29-51af-83ae5f1cc649/cover136x136.jpeg",
            "name": "傷心的人別聽慢歌 (貫徹快樂)",
            "provide_by": "五月天",
            "type": "歌曲",
            "bought_from": "Mac",
            "price": 20000
          }]
        }, {
          "store_name": "iCloud",
          "items": [{
            "image_url": "http://r.mzstatic.com/email/images_shared/dItemArtiCloud2x.jpg",
            "name": "iCloud：50 GB 儲存空間方案",
            "provide_by": "每月 | 2015年01月01日",
            "type": "iCloud 儲存空間",
            "bought_from": "",
            "price": 30000
          }]
        }, {
          "store_name": "Mac App Store",
          "items": [{
            "image_url": "http://a624.phobos.apple.com/us/r30/Purple5/v4/d4/d3/1f/d4d31f1b-bbe8-2e76-44ce-4a6df3f5f377/icon128.png",
            "name": "iMovie",
            "provide_by": "Apple",
            "type": "App",
            "bought_from": "Mac",
            "price": 450000
          }]
        }, {
          "store_name": "App Store",
          "items": [{
            "image_url": "http://is1.mzstatic.com/image/thumb/Purple69/v4/75/73/a9/7573a969-6d71-0ee3-b721-4a334d76f38b/source/120x120bb-80.jpg",
            "name": "BEAKER by THIX",
            "provide_by": "THIX",
            "type": "iOS App",
            "bought_from": "My iPhone 5S",
            "price": 90000
          }, {
            "image_url": "http://is3.mzstatic.com/image/thumb/Purple69/v4/84/bf/46/84bf4660-16b4-4e8e-0322-d8187f3e92f1/source/120x120bb-80.jpg",
            "name": "The Swords",
            "provide_by": "Lee-Kuo Chen",
            "type": "iOS App",
            "bought_from": "My iPhone 5S",
            "price": 90000
          }, {
            "image_url": "http://is1.mzstatic.com/image/thumb/Purple49/v4/7d/df/28/7ddf280c-e7a3-ca63-16d4-8f296fd73177/source/120x120bb-80.jpg",
            "name": "Walkr - 口袋裡的銀河冒險, 一堆能量方塊",
            "provide_by": "",
            "type": "App 內購買項目",
            "bought_from": "My iPhone 5S",
            "price": 150000
          }]
        }]
      }
    EOF
    syncer.parsed_data.create! uid: SecureRandom.uuid, raw_data: <<-EOF
      {
        "apple_id": "xxxx@gmail.com",
        "paid_with": ["visa", "9999"],
        "amount": 270000,
        "date": "2015/03/28",
        "order_id": "IDMHS0000000",
        "store_orders": [{
          "store_name": "App Store",
          "items": [{
            "image_url": "http://is1.mzstatic.com/image/thumb/Purple49/v4/bb/c4/28/bbc428dc-bdd5-1015-613b-f47dc4bc4232/source/120x120bb-80.jpg",
            "name": "Prune",
            "provide_by": "Joel McDonald",
            "type": "iOS App",
            "bought_from": "My iPhone 5S",
            "price": 120000
          }, {
            "image_url": "http://is4.mzstatic.com/image/thumb/Purple7/v4/41/f3/be/41f3be90-c2b6-ee5e-84e7-9d0d097d1399/source/120x120bb-80.jpg",
            "name": "Blek",
            "provide_by": "kunabi brother GmbH",
            "type": "iOS App",
            "bought_from": "My iPhone 5S",
            "price": 90000
          }, {
            "image_url": "http://is5.mzstatic.com/image/thumb/Purple69/v4/5c/36/17/5c3617c7-c23a-7782-1282-d5817e139516/source/120x120bb-80.jpg",
            "name": "Smash Hit, Premium",
            "provide_by": " ",
            "type": "App 內購買項目",
            "bought_from": "My iPhone 5S",
            "price": 60000
          }]
        }]
      }
    EOF
  end
end
