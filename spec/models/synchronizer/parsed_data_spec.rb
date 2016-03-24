require 'rails_helper'

RSpec.describe Synchronizer::ParsedData, type: :model do
  it { is_expected.to belong_to(:synchronizer) }
  it { is_expected.to belong_to(:collected_page) }
  it { is_expected.to have_many(:transactions) }
  it { is_expected.to validate_presence_of(:uid) }
  it { is_expected.to validate_presence_of(:synchronizer) }

  describe "#data" do
    it "gets and sets the data" do
      parsed_data = Synchronizer::ParsedData.new
      parsed_data.data = { text: 'something' }
      expect(parsed_data.data).to eq(HashWithIndifferentAccess.new(text: 'something'))
      expect(parsed_data.raw_data).not_to be_blank
    end
  end
end
