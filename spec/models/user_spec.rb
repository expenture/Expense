require 'rails_helper'

RSpec.describe User, type: :model do
  describe "instantiation" do
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
