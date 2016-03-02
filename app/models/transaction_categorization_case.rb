class TransactionCategorizationCase < ApplicationRecord
  belongs_to :user, optional: true
end
