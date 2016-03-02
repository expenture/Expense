class TransactionCategorizationCase < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :the_transaction, class_name: :Transaction,
                               primary_key: :uid, foreign_key: :transaction_uid,
                               optional: true
end
