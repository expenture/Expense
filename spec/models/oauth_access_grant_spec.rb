require 'rails_helper'

RSpec.describe OAuthAccessGrant, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:oauth_application) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:oauth_application) }
end
