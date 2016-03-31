require 'rails_helper'

RSpec.describe AccountIdentifier, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:identifier) }

  it "should validate that the account exists if account_uid is not blank" do
    ai = AccountIdentifier.new(user: create(:user), identifier: 'xxxx')
    expect(ai).to be_valid
    ai.account_uid = 'xxxx'
    expect(ai).not_to be_valid
  end

  it "should validate that the account belongs to the user if the account is not blank" do
    user = create(:user)
    ai = AccountIdentifier.new(user: user, identifier: 'xxxx', account_uid: create(:account, user: user).uid)
    expect(ai).to be_valid
    ai.account_uid = create(:account)
    expect(ai).not_to be_valid
  end
end
