# == Schema Information
#
# Table name: synchronizer_parsed_data
#
# *id*::                <tt>integer, not null, primary key</tt>
# *collected_page_id*:: <tt>integer</tt>
# *synchronizer_uid*::  <tt>string, not null</tt>
# *uid*::               <tt>string, not null</tt>
# *attribute_1*::       <tt>string</tt>
# *attribute_2*::       <tt>string</tt>
# *raw_data*::          <tt>text</tt>
# *organized_at*::      <tt>datetime</tt>
# *skipped_at*::        <tt>datetime</tt>
# *created_at*::        <tt>datetime, not null</tt>
# *updated_at*::        <tt>datetime, not null</tt>
#
# Indexes
#
#  index_synchronizer_parsed_data_on_collected_page_id  (collected_page_id)
#  index_synchronizer_parsed_data_on_organized_at       (organized_at)
#  index_synchronizer_parsed_data_on_skipped_at         (skipped_at)
#  index_synchronizer_parsed_data_on_synchronizer_uid   (synchronizer_uid)
#  index_synchronizer_parsed_data_on_uid                (uid) UNIQUE
#--
# == Schema Information End
#++

class Synchronizer::ParsedData < ApplicationRecord
  scope :unorganized, -> { where(organized_at: nil, skipped_at: nil) }

  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid
  belongs_to :collected_page, class_name: 'Synchronizer::CollectedPage'
  has_many :transactions, primary_key: :uid,
                          foreign_key: :synchronizer_parsed_data_uid

  validates :uid, :synchronizer, presence: true

  before_validation :set_raw_data

  def data
    @data ||= HashWithIndifferentAccess.new(raw_data && JSON.parse(raw_data))
  end

  def data=(data)
    data = HashWithIndifferentAccess.new(data) unless data.is_a? HashWithIndifferentAccess
    @data = data
    self.raw_data = data.to_json
  end

  def organized!
    self.organized_at = Time.now
    save!
  end

  def skipped!
    self.skipped_at = Time.now
    save!
  end

  private

  def set_raw_data
    self.raw_data = data.to_json
  end
end
