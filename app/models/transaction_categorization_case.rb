# == Schema Information
#
# Table name: transaction_categorization_cases
#
# *id*::              <tt>integer, not null, primary key</tt>
# *user_id*::         <tt>integer</tt>
# *words*::           <tt>string</tt>
# *category_code*::   <tt>string</tt>
# *created_at*::      <tt>datetime, not null</tt>
# *updated_at*::      <tt>datetime, not null</tt>
# *transaction_uid*:: <tt>string</tt>
#
# Indexes
#
#  index_transaction_categorization_cases_on_category_code    (category_code)
#  index_transaction_categorization_cases_on_transaction_uid  (transaction_uid)
#  index_transaction_categorization_cases_on_user_id          (user_id)
#--
# == Schema Information End
#++

class TransactionCategorizationCase < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :the_transaction, class_name: :Transaction,
                               primary_key: :uid, foreign_key: :transaction_uid,
                               optional: true
end
