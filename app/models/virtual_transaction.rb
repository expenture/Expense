class VirtualTransaction < Transaction
  belongs_to :separate_transaction, class_name: 'Transaction',
                                    primary_key: :uid,
                                    foreign_key: :separate_transaction_uid

  validates :separate_transaction, presence: true
  validates :separating_transactions, absence: true
end
