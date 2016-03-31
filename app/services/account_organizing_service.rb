module AccountOrganizingService
  class << self
    def clean(account)
      account.reload

      account.transactions.not_on_record.find_each do |transaction|
        record_transaction = account.transactions.on_record.order(datetime: :desc).possible_copy(transaction.amount, transaction.datetime).first
        next unless record_transaction

        transaction.record_transaction = record_transaction
        transaction.ignore_in_statistics = true
        transaction.save!

        transaction.separating_transactions.each do |separating_transaction|
          separating_transaction.ignore_in_statistics = true
          separating_transaction.save!
        end

        unless record_transaction.manually_edited?
          record_transaction.assign_attributes transaction.serializable_hash.except(*%w(id uid account_uid amount datetime separated separate_transaction_uid on_record record_transaction_uid ignore_in_statistics hidden synchronizer_parsed_data_uid created_at updated_at))
          record_transaction.save!
        end

        if transaction.separated? && !record_transaction.separated?
          transaction.separating_transactions.each do |separating_transaction|
            new_st = record_transaction.separating_transactions.build separating_transaction.serializable_hash.except(*%w(id uid account_uid separated separate_transaction_uid on_record record_transaction_uid ignore_in_statistics hidden synchronizer_parsed_data_uid created_at updated_at))
            new_st.uid = separating_transaction.uid + '-rs-' + SecureRandom.hex(4)
            new_st.save!
          end
        end
      end
    end

    def merge(source_account, target_account)
      source_account.reload
      target_account.reload

      source_account.transactions.not_virtual.find_each do |source_transaction|
        target_transaction = target_account.transactions.build source_transaction.serializable_hash.except(*%w(id uid account_uid separated separate_transaction_uid on_record record_transaction_uid synchronizer_parsed_data_uid created_at updated_at))
        target_transaction.uid = source_transaction.uid + '-mg-' + SecureRandom.hex(4)
        target_transaction.on_record = false
        target_transaction.save!

        if source_transaction.separated?
          source_transaction.separating_transactions.each do |source_separating_transaction|
            target_separating_transaction = target_transaction.separating_transactions.build source_separating_transaction.serializable_hash.except(*%w(id uid account_uid separated separate_transaction_uid on_record record_transaction_uid synchronizer_parsed_data_uid created_at updated_at))
            target_separating_transaction.uid = source_separating_transaction.uid + '-mg-' + SecureRandom.hex(4)
            target_separating_transaction.save!
          end
        end
      end

      clean(target_account)
    end
  end
end
