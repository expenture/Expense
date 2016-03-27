# 國泰世華銀行 MyBank 同步器
#
# 由國泰世華銀行網路銀行同步存款交易紀錄與維護相應帳戶。
#
class CathayUnitedBankSyncer < Synchronizer
  CODE = :cathay_united_bank
  REGION_CODE = :tw
  TYPE = :bank
  COLLECT_METHODS = [:run].freeze
  NAME = '國泰世華銀行'.freeze
  DESCRIPTION = '從國泰世華銀行的「存款帳戶」，同步帳戶與交易資料'.freeze
  INTRODUCTION = <<-EOF.strip_heredoc
  EOF
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
      name: '身分證字號',
      description: '您的身分證字號',
      required: true,
      format: /\A[A-Z]\d{9}\z/
    },
    2 => {
      name: '理財密碼',
      description: '4 位阿拉伯數字的理財 (僅供資料查詢用) 密碼',
      required: true,
      format: /\A\d{4}\z/
    },
    3 => {
      name: '用戶代號',
      description: '6~12 位英數字混合',
      required: true,
      format: /\A[A-Za-z0-9]{6,12}\z/
    }
  }.freeze

  class Collector < Worker
    def run(level: :normal)
      start_run(level)
      open_session
      try_to_login
      save_all_account_pages
    rescue Exception => e
      handle_error(e)
    ensure
      quit_session
      raise_if_error
    end

    private

    def start_run(level)
      @exception = nil
      @level = level
    end

    def handle_error(e)
      log_error e
      @exception = e
    end

    def raise_if_error
      raise @exception if @exception
    end

    def open_session
      @session = Capybara::Session.new(:poltergeist)
    end

    def quit_session
      @session.driver.quit
    end

    def try_to_login
      login_tries = 100
      loop do
        login
        break if login?
        login_tries -= 1
        raise if login_tries == 0
      end
    end

    def login
      @session.visit('https://www.mybank.com.tw/mybank')

      verification_code = get_verification_code_from_page
      log_debug "Using verification_code: #{verification_code}"
      return if verification_code.blank?

      @session.evaluate_script("document.getElementById('CustID').value = '#{passcode_1}';")
      @session.evaluate_script("document.getElementById('passwordKeyin').value = '#{passcode_2}';")
      @session.evaluate_script("document.getElementById('UserIdKeyin').value = '#{passcode_3}';")
      @session.evaluate_script("document.getElementById('ImageCheckCode').value = '#{verification_code}';")
      @session.evaluate_script("document.getElementById('signInButton').click();")
      sleep rand * 3

      raise Synchronizer::ServiceAuthenticationError if @session.driver.source.match('連續錯誤次數') ||
                                                        @session.driver.source.match('尚未申請此系統')
    end

    def get_verification_code_from_page
      sleep 0.5
      verification_image_file_path = "/tmp/#{Base64.urlsafe_encode64(uid).delete('=')}-#{SecureRandom.hex}.png"
      @session.driver.save_screenshot verification_image_file_path, selector: '#ChkCodeImg'
      verification_image = Magick::ImageList.new(verification_image_file_path)
      verification_image = verification_image.white_threshold(Magick::QuantumRange * 0.64).quantize(256, Magick::GRAYColorspace)
      verification_code = RTesseract.new(verification_image).to_s
      File.delete(verification_image_file_path)
      verification_code.gsub!(/[^0-9]/, '')
      return verification_code
    end

    def login?
      @session.has_content?('上次登入成功時間')
    end

    def save_all_account_pages
      account_names = get_account_names
      log_debug "account_names: #{account_names}"

      account_names.each do |account_name|
        log_debug "processing: #{account_name}"
        save_account_page(account_name)
      end
    end

    def get_account_names
      @session.within('#sidenav') { @session.click_on('帳戶明細', match: :first) }
      tries = 20
      account_names = []
      loop do
        sleep 1
        html_doc = Nokogiri::HTML(@session.driver.body)
        account_names = html_doc.css('.searchDrop li').map { |li| li.try(:text) }.compact.uniq.delete_if { |s| s == '請選擇' || s.length < 12 }
        break if account_names.count > 0
        tries -= 1
        raise if tries == 0
      end
      return account_names
    end

    def save_account_page(account_name)
      account_number = account_name.match(/^\d{10,16}/)[0]
      account_type_desc = account_name.gsub(/^\d{10,16}[　 ]*/, '').strip
      @session.within('#sidenav') { @session.click_on('帳戶明細', match: :first) }
      sleep 1

      log_debug "selecting #{account_number} (#{account_type_desc})"
      tries = 32
      loop do
        begin
          @session.within('.contentArea form .searchDrop') { @session.click_on('請選擇', match: :first) }
          sleep 0.5
          break
        rescue Exception => e
          tries -= 1
          raise e if tries == 0
        end
      end

      log_debug "clicking #{account_number} (#{account_type_desc})"
      tries = 32
      loop do
        begin
          @session.within('.contentArea form .searchDrop') { @session.find(:xpath, "//*[text()='#{account_name}']").click }
          sleep 0.5
          break
        rescue Exception => e
          tries -= 1
          raise e if tries == 0
        end
      end

      log_debug "seting query date range for #{account_number} (#{account_type_desc})"
      tries = 12
      loop do
        begin
          @session.within('.contentArea') { @session.find_button('近 30 天', match: :first).trigger('click') }
          sleep 0.5
          start_day_value = @session.find('#StartDay').value
          start_day = Date.parse(start_day_value)
          start_day -= 5.months
          @session.find('#StartDay').set(start_day.to_s)
          sleep 0.5
          break
        rescue Exception => e
          tries -= 1
          raise e if tries == 0
        end
      end
      sleep 3

      log_debug "clicking query for #{account_number} (#{account_type_desc})"
      @session.within('.contentArea') { @session.click_on('查詢', match: :first) }

      log_debug "waiting for the page to load - #{account_number} (#{account_type_desc})"
      sleep 8
      html = @session.find('.tableHolder')['innerHTML']
      collected_pages.create!(body: html, attribute_1: account_number, attribute_2: account_type_desc)
    end
  end

  Synchronizer.register(self)
end
