class Synchronizer::ParsedData < ApplicationRecord
  scope :organized, -> { where(organized_at: nil) }

  belongs_to :synchronizer, primary_key: :uid, foreign_key: :synchronizer_uid
  belongs_to :collected_page, class_name: 'Synchronizer::CollectedPage'
  belongs_to :the_transaction, primary_key: :uid, foreign_key: :transaction_uid
  belongs_to :account, primary_key: :uid, foreign_key: :account_uid

  validates :synchronizer, presence: true

  def data
    @data ||= HashWithIndifferentAccess.new(raw_data && JSON.parse(raw_data))
  end

  def data=(data)
    data = HashWithIndifferentAccess.new(data) unless data.is_a? HashWithIndifferentAccess
    @data = data
    self.raw_data = data.to_json
  end
end
