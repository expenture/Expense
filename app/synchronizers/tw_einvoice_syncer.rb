# 台灣財政部電子發票整合服務平台 - 手機條碼載具電子發票消費記錄同步器
#
# 依照電子發票資料一經開出便不再修改的特性，在解析 (parse) 階段若發現相同的發票已經被解析過，
# 便會略過該張發票的解析。因此 `parsed_data` 將能維持不重複、一張發票對應一筆資料。
#
# == 帳戶管理規則:
# 每張電子發票中可以抓取到載具類別以及代碼 (詳見 `TWEInvoiceSyncer::KNOWN_ACCOUNT_TYPES`
# 常數)。帳戶會依照查詢到的電子發票紀錄自動建立，uid 編碼方式為:
# `<user_id>-<account_type>-<載具代碼>`，其中 `account_type` 為本程式編制的通用帳戶種類
# 代碼，例如悠遊卡為 `tw_eazycard`，`載具代碼` 是電子發票系統中提供的載具代碼。
#
# == 交易記錄 uid 規則:
# `<帳戶 id>-<發票號碼>`
#
class TWEInvoiceSyncer < Synchronizer
  CODE = :tw_einvoice
  REGION_CODE = :tw
  TYPE = :einvoice
  COLLECT_METHODS = [:run].freeze
  NAME = '電子發票'.freeze
  DESCRIPTION = '使用電子發票手機條碼，或是悠遊卡、博客來會員等載具，自動歸戶到「財政部電子發票整合服務平台」的電子發票。'.freeze
  SCHEDULE_INFO = {
    normal: {
      description: '一天兩次－中午與午夜',
      times: %w(00:00 12:00)
    },
    high_frequency: {
      description: '每小時',
      times: %w(**:00)
    },
    low_frequency: {
      description: '每天午夜',
      times: %w(00:00)
    }
  }.freeze
  PASSCODE_INFO = {
    1 => {
      name: '手機號碼',
      description: '您的「財政部電子發票整合服務平台」註冊手機號碼',
      required: true,
      format: /09\d{8}/
    },
    2 => {
      name: '驗證碼',
      description: '「財政部電子發票整合服務平台」登入驗證碼 (等同密碼)',
      required: true
    }
  }.freeze
  KNOWN_ACCOUNT_TYPES = {
    # 手機條碼
    '3J0002' => 'tw_einvoice_general_carrier',
    # 悠遊卡
    '1K0001' => 'tw_eazycard',
    # iCash
    '2G0001' => 'tw_icash'
  }.freeze

  class Collector < Worker
    def run(level: :normal)
      @level = level
      open_session
      try_to_login
      get_available_year_months
      crawl_each_year_months
      quit_session
    end

    private

    def open_session
      @session = Capybara::Session.new(:poltergeist)
    end

    def quit_session
      @session.driver.quit
    end

    def try_to_login
      login_tries = 24
      login
      until login?
        raise if login_tries == 0
        login
        login_tries -= 1
      end
    end

    def login
      @session.visit('https://www.einvoice.nat.gov.tw/APMEMBERVAN/GeneralCarrier/generalCarrier!login')

      verification_image_file_name = "/tmp/#{uid}-#{SecureRandom.hex}.png"
      @session.driver.save_screenshot verification_image_file_name, selector: '.forwardForm img'
      verification_code = RTesseract.new(verification_image_file_name).to_s
      system "rm #{verification_image_file_name}"
      verification_code.gsub!(/[^A-Za-z0-9]/, '')
      log_debug "Using verification_code: #{verification_code}"
      return if verification_code.length < 5

      @session.evaluate_script("document.getElementById('mobile').value = '#{passcode_1}';")
      sleep rand
      @session.evaluate_script("document.getElementById('verifyCode').value = '#{passcode_2}';")
      sleep rand
      @session.evaluate_script("document.getElementById('imageCode').value = '#{verification_code}';")
      sleep rand
      @session.evaluate_script("maintain();")
      sleep rand * 3

      raise Synchronizer::ServiceAuthenticationError if @session.driver.source.match('手機或驗證碼錯誤')
    end

    def login?
      !@session.has_content?('登入')
    end

    def get_available_year_months
      @session.visit('https://www.einvoice.nat.gov.tw/APMEMBERVAN/GeneralCarrier/QueryInv')
      year_month_options = @session.find('#queryInvDate').all('option').collect(&:value)
      @year_months = year_month_options.map { |s| s.match(%r{(\d\d\d\d)\/(\d\d)}).to_a[1..2].map(&:to_i) }
    end

    def crawl_each_year_months
      @year_months.each do |year_month|
        t = Time.new(year_month[0], year_month[1])
        break if last_collected_at && last_collected_at - t > 2.months
        collect_page(year_month[0], year_month[1])
        break if @level == :light
      end
    end

    def collect_page(year, month)
      navigate_to_query_page(year, month)

      html_doc = Nokogiri::HTML(@session.driver.source)
      query_js_codes = html_doc.css('#invoiceTable tr td:nth-child(4) a').map { |a| a.attribute('href').try(:value) }.compact.map { |s| s.gsub(/^javascript:/, '') }

      query_js_codes.each do |query_js_code|
        body = nil
        get_data_tries = 12

        while body.blank?
          raise if get_data_tries == 0

          puts query_js_code
          navigate_to_query_page(year, month) if get_data_tries < 10
          @session.evaluate_script(query_js_code)
          sleep 0.8
          html_doc = Nokogiri::HTML(@session.driver.source)
          body = html_doc.css('#QueryInv').to_html.gsub(/[\t\n]/, '')
          @session.evaluate_script("window.history.back();")
          sleep 0.8

          get_data_tries -= 1
        end

        collected_pages.create!(body: body, attribute_1: query_js_code)
      end
    end

    def navigate_to_query_page(year, month)
      @session.visit('https://www.einvoice.nat.gov.tw/APMEMBERVAN/GeneralCarrier/QueryInv')
      @session.evaluate_script("document.getElementById('queryInvDate').value = '#{format('%04d', year)}/#{format('%02d', month)}';")
      @session.click_on('查詢')
    end
  end

  class Parser < Worker
    def run(level: :normal)
      if level == :complete
        cps = collected_pages.all
      else
        cps = collected_pages.unparsed
      end

      cps.find_each do |collected_page|
        html_doc = Nokogiri::HTML(collected_page.body)
        if html_doc.css('.cp table').blank?
          collected_page.skipped!
          next
        end

        query_js_code = collected_page.attribute_1
        m = query_js_code.match(/queryDetail\(\'[^']*', *'[^']*', *'[^']*', *'[^']*', *'[^']*', *'[^']*', *'[^']*', *'(?<type>[^']*)', *'(?<code>[^']*)'/)
        if m.blank?
          collected_page.skipped!
          next
        end
        account_type = m[:type]
        account_type = KNOWN_ACCOUNT_TYPES[account_type] || account_type
        account_code = m[:code]

        invoice_code = html_doc.css('.cp table tr:nth-child(2) td:nth-child(1)').text.strip

        if parsed_data.exists?(uid: "#{uid}-#{invoice_code}")
          collected_page.skipped!
          next
        end

        date_string = html_doc.css('.cp table tr:nth-child(2) td:nth-child(2)').text.strip
        seller_name = html_doc.css('.cp table tr:nth-child(2) td:nth-child(3)').text.strip + ' ' + html_doc.css('.cp table tr:nth-child(2) td:nth-child(4)').text.strip
        amount = html_doc.css('.cp table tr:nth-child(2) td:nth-child(5)').text.to_i * 1_000

        date_string_m = date_string.match(%r{(?<taiwan_year>\d+)\/(?<month>\d+)\/(?<day>\d+)})
        year = date_string_m[:taiwan_year].to_i + 1911
        month = date_string_m[:month].to_i
        day = date_string_m[:day].to_i
        datetime = Time.new(year, month, day, 0, 0, 0, '+08:00')

        details = html_doc.css('#invoiceDetailTable tbody tr').each_with_index.map do |tr, i|
          {
            number: i,
            name: tr.css('td:nth-child(1)').text.strip,
            count: tr.css('td:nth-child(2)').text.to_i,
            price: tr.css('td:nth-child(3)').text.to_i * 1_000,
            amount: tr.css('td:nth-child(4)').text.to_i * 1_000
          }
        end

        new_parsed_data = collected_page.parsed_data.build(uid: "#{uid}-#{invoice_code}")
        new_parsed_data.data = {
          account_type: account_type,
          account_code: account_code,
          invoice_code: invoice_code,
          seller_name: seller_name,
          amount: amount,
          datetime: datetime,
          details: details
        }
        new_parsed_data.save!
        collected_page.parsed!
      end
    end
  end

  class Organizer < Worker
    def run(level: :normal)
      if level == :complete
        pds = parsed_data.all
      else
        pds = parsed_data.unorganized
      end

      pds.find_each do |the_parsed_data|
        data = the_parsed_data.data

        account_identifier = \
          account_identifiers.find_or_initialize_by type: data[:account_type],
                                                    identifier: data[:account_code]

        if !account_identifier.identified? &&
           (account_identifier.sample_transaction_datetime.blank? ||
           DateTime.parse(data[:datetime]) > account_identifier.sample_transaction_datetime)
          account_identifier.sample_transaction_party_name = data[:seller_name]
          account_identifier.sample_transaction_description = "#{data[:details][0][:name]} × #{data[:details][0][:count]}"
          account_identifier.sample_transaction_amount = -data[:details][0][:amount]
          account_identifier.sample_transaction_datetime = data[:datetime]
        end

        account_identifier.save! if account_identifier.new_record? || account_identifier.changed?

        if account_identifier.account.present?
          account = account_identifier.account

          if account.transactions.exists?(synchronizer_parsed_data_uid: the_parsed_data.uid)
            the_parsed_data.skipped!
          else
            # TODO: log seller_name
            transaction = account.transactions.create!(
              synchronizer_parsed_data: the_parsed_data,
              uid: "#{account.id}-#{uid}-#{data[:invoice_code]}",
              description: "在 #{data[:seller_name]} 消費 NT$ #{(data[:amount] / 1_000).to_i}",
              amount: -data[:amount],
              datetime: data[:datetime],
              note: (
                <<-EOD.strip_heredoc
                  發票號碼：#{data[:invoice_code]}
                  發票開立日期：#{DateTime.parse(data[:datetime]).strftime('%Y/%m/%d')}
                  賣方名稱與統編：#{data[:seller_name]}
                  發票金額：#{(data[:amount] / 1_000).to_i}
                  消費明細：
                EOD
              ) + data[:details].map { |d| "#{d[:name]}：NT$ #{d[:price]/1000} × #{d[:count]} = NT$ #{d[:amount]/1000}" }.join("\n")
            )

            data[:details].each do |detail|
              if detail[:amount] < 0
                category_code = 'discounts'
              else
                @tcs ||= user.transaction_category_set
                category_code = @tcs.categorize(detail[:name], datetime: DateTime.parse(data[:datetime]), latitude: 23.5, longitude: 121)
              end

              transaction.separating_transaction.create!(
                synchronizer_parsed_data: the_parsed_data,
                uid: "#{account.id}-#{uid}-#{data[:invoice_code]}-#{detail[:number]}",
                description: (detail[:count] > 1 ? "#{detail[:name]} × #{detail[:count]}" : detail[:name]),
                amount: -detail[:amount],
                category_code: category_code
              )
            end

            the_parsed_data.organized!
          end
        end
      end
    end
  end

  Synchronizer.register(self)
end
