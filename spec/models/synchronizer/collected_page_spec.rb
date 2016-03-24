require 'rails_helper'

RSpec.describe Synchronizer::CollectedPage, type: :model do
  it { is_expected.to belong_to(:synchronizer) }
  it { is_expected.to have_many(:parsed_data) }
  it { is_expected.to validate_presence_of(:synchronizer) }
end
