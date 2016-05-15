require 'rails_helper'

RSpec.describe OAuthAccessToken, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:oauth_application) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:oauth_application) }

  it "must belong to an oauth_application" do
    # OAuthAccessToken is an "documentation wrapper" of the class
    # Doorkeeper::AccessToken, so here we test on the real class directly
    expect { Doorkeeper::AccessToken.create!(resource_owner_id: create(:user, :confirmed).id) }.to raise_error
    expect { Doorkeeper::AccessToken.create!(resource_owner_id: create(:user, :confirmed).id, application: create(:oauth_application)) }.not_to raise_error
  end
end
