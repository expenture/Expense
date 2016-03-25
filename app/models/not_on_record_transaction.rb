class NotOnRecordTransaction < Transaction
  belongs_to :record_transaction, class_name: 'Transaction',
                                  primary_key: :uid,
                                  foreign_key: :record_transaction_uid

  after_initialize :set_on_record_to_false
  before_validation :set_on_record_to_false

  private

  def set_on_record_to_false
    self.on_record = false
  end
end
