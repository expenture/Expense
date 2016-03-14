class Account < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :user
  has_many :transactions,
           primary_key: :uid, foreign_key: :account_uid
  has_many :synchronizer_parsed_data, class_name: 'Synchronizer::ParsedData',
                                      primary_key: :uid, foreign_key: :account_uid

  validates :user, :uid, :type, :name, :currency, :balance, presence: true
  validates :uid, uniqueness: true

  def default?
    return false unless persisted?
    reload
    user.default_account_uid == uid
  end

  def destroy
    if default?
      errors.add :base, 'Cannot destroy a default account'
      return false
    else
      super
    end
  end
end
