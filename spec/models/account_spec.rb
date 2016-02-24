require 'rails_helper'

RSpec.describe Account, type: :model do
  context "user sets this account as default" do
    subject(:account) { create(:account, :default) }

    it { is_expected.to be_default }

    it "can't be destroyed" do
      expect { account.destroy! }.to raise_error
    end
  end

  context "user doesn't sets this account as default" do
    subject(:account) { create(:account) }

    it { is_expected.not_to be_default }

    it "can be destroyed" do
      expect { account.destroy! }.not_to raise_error
    end
  end
end
