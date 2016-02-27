class User < ApplicationRecord
  attr_accessor :from
  devise :database_authenticatable, :omniauthable, :registerable, :confirmable,
         :timeoutable, :lockable, :recoverable, :trackable, :validatable

  has_many :accounts
  belongs_to :default_account, class_name: :Account,
             primary_key: :uid, foreign_key: :default_account_uid,
             optional: true
  has_many :transactions, through: :accounts

  validates :default_account, presence: true, on: :update

  after_create :create_default_account
  before_validation :check_password

  def link_to_facebook_by_data(data, save: true)
    self.name = data[:name] if self.name.blank?

    self.external_profile_picture_url = data[:picture_url] if data[:picture_url].present?
    self.external_cover_photo_url = data[:cover_url] if data[:cover_url].present?

    self.fb_id = data[:id]
    self.fb_email = data[:email]

    self.save! if save

    return self
  end

  def link_to_facebook_by_access_token(access_token)
    self.link_to_facebook_by_data(FacebookService.user_data_from_facebook_access_token(access_token), save: false)

    self.fb_access_token = access_token
    self.save!

    return self
  end

  private

  def create_default_account
    self.default_account = Account.new(user_id: id, uid: "#{id}-#{SecureRandom.uuid}", name: 'default')
    self.default_account.save!
    self.save!
  end

  def check_password
    if self.from == 'facebook'
      self.password = SecureRandom.hex(36) if encrypted_password.blank?
    elsif persisted? == false
      self.password_set_at = Time.now
    else
      self.password_set_at = Time.now if encrypted_password_changed?
    end
  end

  class << self
    def from_facebook_access_token(access_token)
      fb_user_data = FacebookService.user_data_from_facebook_access_token(access_token)

      if fb_user_data
        user = User.find_by(fb_id: fb_user_data[:id]) ||
               User.find_by(fb_email: fb_user_data[:email]) ||
               User.find_by(email: fb_user_data[:email]) ||
               User.new(email: fb_user_data[:email], name: fb_user_data[:name])

        user.from = 'facebook'
        user.fb_access_token = access_token
        user.link_to_facebook_by_data(fb_user_data, save: false) if user.fb_id.blank?

        user.save!
        return user
      else
        return nil
      end
    end
  end
end
