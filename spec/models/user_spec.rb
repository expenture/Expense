require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:accounts) }
  it { is_expected.to belong_to(:default_account) }
  it { is_expected.to have_many(:transactions) }
  it { is_expected.to have_many(:transaction_categorization_cases) }
  it { is_expected.to have_many(:synchronizers) }
  it { is_expected.to have_many(:account_identifiers) }

  describe "instance" do
    subject(:user) { create(:user) }

    context "after created" do
      it { is_expected.not_to be_confirmed }
      its(:default_account) { is_expected.to be_an(Account) }
      its(:default_account) { is_expected.to be_default }
    end

    it "must have a default account" do
      user.default_account = nil

      expect(user.save).to be(false)
    end
  end
end
