class AppleReceiptSyncer < Synchronizer
  CODE = :apple_receipt
  REGION_CODE = nil
  TYPE = :receipt
  COLLECT_METHODS = [:email].freeze
  NAME = 'Receipts from Apple'.freeze
  DESCRIPTION = 'Email receipts for the App Store, iTunes, iBooks from Apple inc.'.freeze
  INTRODUCTION = <<-EOF.strip_heredoc
  EOF
  SCHEDULE_INFO = {
    normal: {
      description: '每小時',
      times: %w(**:00)
    },
    high_frequency: {
      description: '每十分鐘',
      times: %w(**:00 **:10 **:20 **:30 **:40 **:50)
    },
    low_frequency: {
      description: '每天午夜',
      times: %w(00:00)
    }
  }.freeze
  EMAIL_ENDPOINT_INTRODUCTION = ''.freeze

  class Collector < Worker
    def receive(data, type: nil)
      case type
      when :email
        collected_pages.create!(body: data, attribute_1: 'email')
      else
        raise NotImplementedError,
              "The type #{type} is not supported!"
      end
    end
  end

  class Parser < Worker
    def run
      pending_collected_pages.find_each do |collected_page|
        html_doc = Nokogiri::HTML(collected_page.body)
        receipt_table = html_doc.css('tbody > tr > td > img[alt=Apple]').first.parent.parent.parent
        receipt_sections = receipt_table.css('> tr > td > table tr > td > table > tbody')

        # Parse bill info
        receipt_section = receipt_sections[0]

        receipt_apple_id = receipt_section.css('> tr:nth-child(1) > td:nth-child(1)').text.gsub(/[\n ]/, '').gsub(/^AppleID/, '')
        receipt_paid_with = receipt_section.css('> tr:nth-child(1) > td:nth-child(2)').text.split(' .... ').each_with_index.map { |s, i| s.tr("\n", ' ').split(' ')[i > 0 ? 0 : -1].downcase } # ["visa", "9999"]
        receipt_amount = receipt_section.css('> tr:nth-child(1) > td:nth-child(3)').text.split('$').last.delete(',').to_i * 1_000
        receipt_date = receipt_section.css('> tr:nth-child(2) > td:nth-child(1)').text.split(/[\n 期]/).last.strip.gsub(/[年月]/, '/').gsub(/[日]/, '')
        receipt_order_id = receipt_section.css('> tr:nth-child(3) > td:nth-child(1)').text.strip.split(' ').last.strip

        new_parsed_data_uid = "#{uid}-#{receipt_order_id}"

        # Skip this page if it is already parsed
        if parsed_data.exists?(uid: new_parsed_data_uid)
          collected_page.skipped!
          next
        end

        # Or init the new parsed_data
        new_parsed_data = parsed_data.new(uid: new_parsed_data_uid)
        new_parsed_data.data = {
          apple_id: receipt_apple_id,
          paid_with: receipt_paid_with,
          amount: receipt_amount,
          date: receipt_date,
          order_id: receipt_order_id
        }
        data = new_parsed_data.data

        # Parse each section, skipping the first (bill info) and last (summery)
        # one, so [1..-2]
        data[:store_orders] = []
        store_counter = 0

        receipt_sections[1..-2].each do |receipt_section|
          data[:store_orders][store_counter] = {}
          store_order_data = data[:store_orders][store_counter]
          store_order_data[:store_name] = receipt_section.css('> tr:nth-child(1) > td:nth-child(1)').text.tr("\n", '').gsub(/ +/, ' ') # 'iTunes Store', 'App Store', 'Mac App Store', etc.

          store_order_data[:items] = []

          item_counter = 0

          receipt_section.css('> tr:not(:first-child)').each do |receipt_item|
            next if receipt_item.text.blank?
            store_order_data[:items][item_counter] = {}
            item_data = store_order_data[:items][item_counter]
            item_data[:image_url] = receipt_item.css('td:nth-child(1) img').attribute('src').value
            item_data[:name] = receipt_item.css('td:nth-child(2) span:nth-of-type(1)').text.tr("\n", ' ').gsub(/ +/, ' ')
            item_data[:provide_by] = receipt_item.css('td:nth-child(2) span:nth-of-type(2)').xpath('text()').text.tr("\n", ' ').gsub(/ +/, ' ')
            item_data[:type] = receipt_item.css('td:nth-child(3)').text.tr("\n", ' ').gsub(/ +/, ' ').strip
            item_data[:bought_from] = receipt_item.css('td:nth-child(4)').text.tr("\n", ' ').gsub(/ +/, ' ').strip
            item_data[:price] = receipt_item.css('td:nth-child(5)').text.split('$').last.strip.delete(',').to_i * 1_000

            item_counter += 1
          end
          store_counter += 1
        end

        new_parsed_data.save!
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
      pending_parsed_data.find_each do |bill_data|
        data = bill_data.data
        account = find_account(type: data[:paid_with][0], identifier: data[:paid_with][1], amount: -data[:amount], datetime: data[:date], description: data[:store_orders][0][:items][0][:name], party_name: 'Apple (iTunes)')

        next if account.blank?

        if account.transactions.exists?(synchronizer_parsed_data_uid: bill_data.uid)
          bill_data.skipped!
          next
        end

        possible_on_record_copy = account.transactions.possible_on_record_copy(-data[:amount], data[:date]).last
        if possible_on_record_copy.present? && possible_on_record_copy.manually_edited?
          bill_data.skipped!
          next
        end

        transaction = possible_on_record_copy || account.transactions.new(
          uid: "#{uid}-apple_receipt-#{data[:order_id]}",
          amount: -data[:amount],
          datetime: data[:date]
        )

        transaction.synchronizer_parsed_data = bill_data
        transaction.party_type ||= 'store'
        transaction.party_code ||= 'apple'
        transaction.party_name ||= 'Apple'
        transaction.note ||= ''
        transaction.note += "\n" if transaction.note.present?
        transaction.note += <<-EOF.strip_heredoc
          Receipt From Apple
          Apple ID: #{data[:apple_id]}
          Order ID: #{data[:order_id]}
          Items:
        EOF
        transaction.note += data[:store_orders].flat_map { |h| h[:items].map { |i| "#{i[:name]} - $ #{i[:price] / 1000.0}" } }.join("\n")
        transaction.save!

        unless transaction.separated?
          data[:store_orders].each do |store_order|
            party_name = store_order[:store_name]
            party_code = store_order[:store_name].tr(' ', '_').downcase
            store_order[:items].each_with_index do |item, i|
              description = [item[:name], item[:provide_by]].delete_if(&:blank?).join(' by ')
              category_code = transaction_category_set.categorize("#{store_order[:store_name]} #{item[:name]} #{item[:provide_by]} #{item[:type]}")
              item_party_name = [party_name, item[:provide_by]].delete_if(&:blank?).join(' | ')
              note = "#{item[:type]}, bought from #{item[:bought_from]}"

              transaction.separating_transactions.create!(
                synchronizer_parsed_data: bill_data,
                uid: "#{uid}-apple_receipt-#{data[:order_id]}-#{party_code}-#{i}",
                amount: -item[:price],
                description: description,
                datetime: data[:date],
                category_code: category_code,
                external_image_url: item[:image_url],
                party_name: item_party_name,
                party_type: 'store',
                party_code: party_code,
                note: note
              )
            end
          end
        end

        bill_data.organized!
      end
    end

    private

    def pending_parsed_data
      if run_level == :complete
        parsed_data.all
      else
        parsed_data.unorganized
      end
    end

    def find_account(type:, identifier:, amount: nil, datetime: nil, description: nil, party_name: nil)
      @accounts ||= {}
      return @accounts["#{type}-#{identifier}"] if @accounts.key?("#{type}-#{identifier}")

      account_identifier = \
        account_identifiers.find_or_initialize_by type: type,
                                                  identifier: identifier

      account_identifier.update_sample_data_if_needed(
        amount: amount,
        datetime: datetime,
        description: description,
        party_name: party_name
      ) if amount && datetime && description && party_name

      @accounts["#{type}-#{identifier}"] = account_identifier.account
      return @accounts["#{type}-#{identifier}"]
    end

    def transaction_category_set
      @transaction_category_set ||= user.transaction_category_set
    end
  end

  Synchronizer.register(self)
end
