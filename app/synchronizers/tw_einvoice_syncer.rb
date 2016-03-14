class TWEInvoiceSyncer < Synchronizer
  CODE = :tw_einvoice
  REGION_CODE = :tw
  NAME = '電子發票'.freeze
  DESCRIPTION = '使用電子發票手機條碼，或是悠遊卡、博客來會員等載具，自動歸戶到「財政部電子發票整合服務平台」的電子發票。'.freeze
  PASSCODE_INFO = {
    1 => {
      name: '手機號碼',
      description: '您的「財政部電子發票整合服務平台」註冊手機號碼',
      required: true
    },
    2 => {
      name: '驗證碼',
      description: '「財政部電子發票整合服務平台」登入驗證碼 (等同密碼)',
      required: true
    }
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
      puts verification_code
      return if verification_code.length < 5

      @session.evaluate_script("document.getElementById('mobile').value = '#{passcode_1}';")
      sleep rand
      @session.evaluate_script("document.getElementById('verifyCode').value = '#{passcode_2}';")
      sleep rand
      @session.evaluate_script("document.getElementById('imageCode').value = '#{verification_code}';")
      sleep rand
      @session.evaluate_script("maintain();")
      sleep rand * 3
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
      @session.visit('https://www.einvoice.nat.gov.tw/APMEMBERVAN/GeneralCarrier/QueryInv')
      @session.evaluate_script("document.getElementById('queryInvDate').value = '#{format('%04d', year)}/#{format('%02d', month)}';")
      @session.click_on('查詢')

      html_doc = Nokogiri::HTML(@session.driver.source)
      query_js_codes = html_doc.css('#invoiceTable tr td:nth-child(4) a').map { |a| a.attribute('href').try(:value) }.compact.map { |s| s.gsub(/^javascript:/, '') }

      query_js_codes.each do |query_js_code|
        puts query_js_code
        @session.evaluate_script(query_js_code)
        sleep 0.8
        html_doc = Nokogiri::HTML(@session.driver.source)
        collected_pages.create!(body: html_doc.css('#QueryInv').to_html.gsub(%r{[\t\n]}, ''))
        @session.evaluate_script("window.history.back();")
        sleep 0.8
      end
    end
  end

  class Parser < Worker
    def run
      collected_pages.unparsed.find_each do |collected_page|
        html_doc = Nokogiri::HTML(collected_page.body)

        if html_doc.css('.cp table').blank?
          collected_page.skipped!
          next
        end

        invoice_code = html_doc.css('.cp table tr:nth-child(2) td:nth-child(1)').text.strip
        date_string = html_doc.css('.cp table tr:nth-child(2) td:nth-child(2)').text.strip
        seller_name = html_doc.css('.cp table tr:nth-child(2) td:nth-child(3)').text.strip + ' ' + html_doc.css('.cp table tr:nth-child(2) td:nth-child(4)').text.strip
        amount = html_doc.css('.cp table tr:nth-child(2) td:nth-child(5)').text.to_i * 1_000

        date_string_m = date_string.match(%r{(?<taiwan_year>\d+)\/(?<month>\d+)\/(?<day>\d+)})
        year = date_string_m[:taiwan_year].to_i + 1911
        month = date_string_m[:month].to_i
        day = date_string_m[:day].to_i
        datetime = Time.new(year, month, day, 0, 0, 0, '+08:00')

        details = html_doc.css('#invoiceDetailTable tbody tr').map do |tr|
          {
            name: tr.css('td:nth-child(1)').text.strip,
            count: tr.css('td:nth-child(2)').text.to_i,
            price: tr.css('td:nth-child(3)').text.to_i * 1_000,
            amount: tr.css('td:nth-child(4)').text.to_i * 1_000
          }
        end

        parsed_data = collected_page.parsed_data.build
        parsed_data.data = {
          invoice_code: invoice_code,
          seller_name: seller_name,
          amount: amount,
          datetime: datetime,
          details: details
        }
        parsed_data.save!
        collected_page.parsed!
      end
    end
  end

  class Organizer < Worker
  end

  Synchronizer.register(self)
end
