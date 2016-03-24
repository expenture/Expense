require 'rails_helper'

RSpec.describe OAuthApplication, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:oauth_access_grant) }
  it { is_expected.to have_many(:oauth_access_token) }
end
