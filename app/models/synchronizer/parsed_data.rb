class Synchronizer::ParsedData < ApplicationRecord
  scope :unorganized, -> { where(organized_at: nil) }

  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid
  belongs_to :collected_page, class_name: 'Synchronizer::CollectedPage'
  has_many :transactions, primary_key: :uid,
                          foreign_key: :synchronizer_parsed_data_uid

  validates :uid, :synchronizer, presence: true

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
end
