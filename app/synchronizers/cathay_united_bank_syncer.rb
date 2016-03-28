# 國泰世華銀行 MyBank 同步器
#
# 自國泰世華銀行 https://www.mybank.com.tw 網路銀行抓取帳戶明細，更新相應帳戶與建立交易紀錄。
# 同步時，`parsed_data` 分為帳戶、與帳戶交易明細兩種。
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
    def run
      open_session
      try_to_login
      save_all_account_pages
      click_logout
    rescue Exception => e
      handle_error(e)
    ensure
      quit_session
      raise_if_error
    end

    private

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
      login_tries = 20
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
      sleep 2

      # 親愛的客戶，您可能已在其他分頁或相同瀏覽器上登入，或前次未正常登出，請按登出按鈕後，即可重新登入使用
      if @session.driver.source.match('請按登出按鈕後')
        log_debug "Login: 親愛的客戶，您可能已在其他分頁或相同瀏覽器上登入，或前次未正常登出，請按登出按鈕後，即可重新登入使用..."
        @session.within('.logout_message') { @session.find('.bSignin').click }
        sleep 0.5
      end

      # 您上次的使用，未完成正常的登出程序
      if @session.driver.body.match('未完成正常的登出程序')
        log_debug "Login: 您上次的使用，未完成正常的登出程序..."
        @session.click_on('重新登入')
        sleep 0.5
      end

      # 登入資訊錯誤
      raise Synchronizer::ServiceAuthenticationError if @session.driver.source.match('連續錯誤次數') ||
                                                        @session.driver.source.match('尚未申請此系統')
      raise if @session.driver.source.match('目前系統維護中')
    end

    def click_logout
      @session.within('#top') { @session.click_on('登出', match: :first) }
    rescue Exception => e
      log_error(e)
    end

    def get_verification_code_from_page
      sleep 2
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

  class Parser < Worker
    def run
      pending_collected_pages.find_each do |collected_page|
        account_num = collected_page.attribute_1
        account_type_desc = collected_page.attribute_2
        account_uid = "#{user_id}-cathay_united_bank-#{account_num}-#{uid}"
        last_transaction_balance = nil

        html_doc = Nokogiri::HTML(collected_page.body)

        day_num_counter = {}

        transactions = html_doc.css('tbody tr').map do |tr|
          date = tr.css('td:nth-child(1)').text
          day_num_counter[date] ||= -1
          day_num_counter[date] += 1
          transaction_uid = "#{user_id}-cathay_united_bank-#{account_num}-#{date.gsub('/', '-')}-#{day_num_counter[date]}-#{uid}"

          amount_out = tr.css('td:nth-child(2)').text # 提出
          amount_in = tr.css('td:nth-child(3)').text # 存入
          if amount_out.present?
            amount = -amount_out.delete(',').to_i
          elsif amount_in.present?
            amount = amount_in.delete(',').to_i
          else
            amount = nil
          end

          balance = tr.css('td:nth-child(4)').text.delete(',').to_i
          last_transaction_balance = balance

          explanation = tr.css('td:nth-child(5)').text.strip
          note = tr.css('td:nth-child(6)').inner_html.gsub('<br>', "\n").strip.gsub(/－\n?\n?$/, '')
          note = '國外交易手續費' if note == '國外交易手'

          if amount.nil?
            nil
          else
            {
              uid: transaction_uid,
              account: account_num,
              date: date,
              amount: amount,
              balance: balance,
              explanation: explanation,
              note: note
            }
          end
        end

        transactions.compact!

        transactions.each do |transaction|
          parsed_data_uid = "transaction-#{transaction[:uid]}"
          transaction_data = parsed_data.find_or_initialize_by(uid: parsed_data_uid)
          next if transaction_data.persisted?
          transaction_data.update_attributes(attribute_1: 'transaction', attribute_2: transaction[:uid], data: transaction)
        end

        account = {
          uid: account_uid,
          num: account_num,
          balance: last_transaction_balance,
          type_desc: account_type_desc
        }

        account_data = parsed_data.find_or_initialize_by(uid: "account-#{account_uid}")
        account_data.update_attributes(attribute_1: 'account', attribute_2: account_uid, data: account, organized_at: nil)

        collected_page.parsed!
      end
    end

    private

    def pending_collected_pages
      if run_level == :complete
        collected_pages.all
      else
        collected_pages.unparsed
      end
    end
  end

  class Organizer < Worker
    def run
      initialize_accounts
      create_transactions
      clean_accounts
    end

    private

    def initialize_accounts
      pending_parsed_data.where(attribute_1: 'account').find_each do |account_data|
        next if accounts.exists?(uid: account_data.data[:uid])
        accounts.create!(uid: account_data.data[:uid], type: 'account', currency: 'TWD', name: "國泰世華銀行 #{account_data.data[:type_desc]} #{account_data.data[:num]}")
      end
    end

    def create_transactions
      pending_parsed_data.where(attribute_1: 'transaction').find_each do |transaction_data|
        data = transaction_data.data
        account = syncer_account(data[:account])
        transaction = transaction_data.transactions.find_or_initialize_by(on_record: true, uid: data[:uid], account: account)
        next if transaction.persisted?

        data_datetime = DateTime.parse(data[:date])
        description = [data[:explanation].tr("\n", ' '), data[:note].tr("\n", ' ')].join('－')

        @tcs ||= user.transaction_category_set
        category_code = @tcs.categorize(description, datetime: data_datetime)

        transaction.update_attributes(
          amount: data[:amount] * 1_000,
          description: description,
          datetime: data_datetime,
          category_code: category_code
        )
      end
    end

    def clean_accounts
      pending_parsed_data.where(attribute_1: 'account').find_each do |account_data|
        account = accounts.find_by!(uid: account_data.data[:uid])
        account.balance = account_data.data[:balance] * 1_000
        account.save!
        AccountOrganizingService.clean(account)
      end
    end

    def pending_parsed_data
      if run_level == :complete
        parsed_data.all
      else
        parsed_data.unorganized
      end
    end

    def syncer_account(account_num)
      @syncer_account ||= {}
      @syncer_account[account_num] ||= accounts.find_by('uid LIKE ?', "%cathay_united_bank-#{account_num}%")
    end
  end

  Synchronizer.register(self)
end
