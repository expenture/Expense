# == Schema Information
#
# Table name: synchronizer_collected_pages
#
# *id*::               <tt>integer, not null, primary key</tt>
# *synchronizer_uid*:: <tt>string, not null</tt>
# *attribute_1*::      <tt>string</tt>
# *attribute_2*::      <tt>string</tt>
# *header*::           <tt>text</tt>
# *body*::             <tt>text</tt>
# *parsed_at*::        <tt>datetime</tt>
# *skipped_at*::       <tt>datetime</tt>
# *created_at*::       <tt>datetime, not null</tt>
# *updated_at*::       <tt>datetime, not null</tt>
#
# Indexes
#
#  index_synchronizer_collected_pages_on_parsed_at         (parsed_at)
#  index_synchronizer_collected_pages_on_skipped_at        (skipped_at)
#  index_synchronizer_collected_pages_on_synchronizer_uid  (synchronizer_uid)
#--
# == Schema Information End
#++

class Synchronizer::CollectedPage < ApplicationRecord
  scope :unparsed, -> { where(parsed_at: nil, skipped_at: nil) }

  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid
  has_many :parsed_data,
           ->(o) { where(:'synchronizer_parsed_data.synchronizer_uid' => o.synchronizer_uid) },
           class_name: 'Synchronizer::ParsedData'

  validates :synchronizer, presence: true

  def parsed!
    self.parsed_at = Time.now
    save!
  end

  def skipped!
    self.skipped_at = Time.now
    save!
  end
end
