# == Schema Information
#
# Table name: transactions
#
# *id*::                           <tt>integer, not null, primary key</tt>
# *uid*::                          <tt>string, not null</tt>
# *account_uid*::                  <tt>string, not null</tt>
# *type*::                         <tt>string</tt>
# *amount*::                       <tt>integer, not null</tt>
# *description*::                  <tt>text</tt>
# *category_code*::                <tt>string</tt>
# *tags*::                         <tt>string</tt>
# *note*::                         <tt>text</tt>
# *datetime*::                     <tt>datetime, not null</tt>
# *latitude*::                     <tt>float</tt>
# *longitude*::                    <tt>float</tt>
# *party_type*::                   <tt>string</tt>
# *party_code*::                   <tt>string</tt>
# *party_name*::                   <tt>string</tt>
# *external_image_url*::           <tt>string</tt>
# *separated*::                    <tt>boolean, default(FALSE), not null</tt>
# *separate_transaction_uid*::     <tt>string</tt>
# *on_record*::                    <tt>boolean</tt>
# *record_transaction_uid*::       <tt>string</tt>
# *synchronizer_parsed_data_uid*:: <tt>string</tt>
# *ignore_in_statistics*::         <tt>boolean, default(FALSE), not null</tt>
# *manually_edited_at*::           <tt>datetime</tt>
# *created_at*::                   <tt>datetime, not null</tt>
# *updated_at*::                   <tt>datetime, not null</tt>
# *deleted_at*::                   <tt>datetime</tt>
#
# Indexes
#
#  index_transactions_on_account_uid                   (account_uid)
#  index_transactions_on_category_code                 (category_code)
#  index_transactions_on_deleted_at                    (deleted_at)
#  index_transactions_on_ignore_in_statistics          (ignore_in_statistics)
#  index_transactions_on_manually_edited_at            (manually_edited_at)
#  index_transactions_on_on_record                     (on_record)
#  index_transactions_on_record_transaction_uid        (record_transaction_uid)
#  index_transactions_on_separate_transaction_uid      (separate_transaction_uid)
#  index_transactions_on_separated                     (separated)
#  index_transactions_on_synchronizer_parsed_data_uid  (synchronizer_parsed_data_uid)
#  index_transactions_on_type                          (type)
#  index_transactions_on_uid                           (uid) UNIQUE
#--
# == Schema Information End
#++

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
