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
