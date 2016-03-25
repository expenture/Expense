require 'rails_helper'

RSpec.describe VirtualTransaction, type: :model do
  it { is_expected.to belong_to(:separate_transaction) }
  it { is_expected.to validate_presence_of(:separate_transaction) }

  it "is expected to validate absence of separating_transactions" do
  end
end
