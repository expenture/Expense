# == Schema Information
#
# Table name: transactions
#
# *id*::                           <tt>integer, not null, primary key</tt>
# *uid*::                          <tt>string, not null</tt>
# *account_uid*::                  <tt>string, not null</tt>
# *kind*::                         <tt>string</tt>
# *amount*::                       <tt>integer, not null</tt>
# *description*::                  <tt>text</tt>
# *category_code*::                <tt>string</tt>
# *tags*::                         <tt>string</tt>
# *note*::                         <tt>text</tt>
# *datetime*::                     <tt>datetime, not null</tt>
# *latitude*::                     <tt>float</tt>
# *longitude*::                    <tt>float</tt>
# *separated*::                    <tt>boolean, default(FALSE), not null</tt>
# *separate_transaction_uid*::     <tt>string</tt>
# *on_record*::                    <tt>boolean</tt>
# *record_transaction_uid*::       <tt>string</tt>
# *ignore_in_statistics*::         <tt>boolean, default(FALSE), not null</tt>
# *synchronizer_parsed_data_uid*:: <tt>string</tt>
# *manually_edited_at*::           <tt>datetime</tt>
# *created_at*::                   <tt>datetime, not null</tt>
# *updated_at*::                   <tt>datetime, not null</tt>
#
# Indexes
#
#  index_transactions_on_account_uid                   (account_uid)
#  index_transactions_on_category_code                 (category_code)
#  index_transactions_on_ignore_in_statistics          (ignore_in_statistics)
#  index_transactions_on_kind                          (kind)
#  index_transactions_on_manually_edited_at            (manually_edited_at)
#  index_transactions_on_on_record                     (on_record)
#  index_transactions_on_record_transaction_uid        (record_transaction_uid)
#  index_transactions_on_separate_transaction_uid      (separate_transaction_uid)
#  index_transactions_on_separated                     (separated)
#  index_transactions_on_synchronizer_parsed_data_uid  (synchronizer_parsed_data_uid)
#  index_transactions_on_uid                           (uid) UNIQUE
#--
# == Schema Information End
#++

class SyncedTransaction < Transaction
  validate :immutable_amount, on: :update

  def destroy
    errors.add :base, 'a SyncedTransaction cannot be destroyed'
    return false
  end

  private

  def immutable_amount
    return unless amount_changed?
    errors.add(:amount, 'is immutable for synced transaction')
  end
end
