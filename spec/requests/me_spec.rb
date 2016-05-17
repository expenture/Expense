require "rails_helper"

describe "User Profile And Settings API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me']
  ]

  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let(:authorization_header) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  describe "GET /me" do
    it "responds with the profile of the current user" do
      get '/me', authorization_header
      expect(response).to be_success
      expect_json_types 'user', id: :integer,
                                name: :string_or_null,
                                email: :string
    end
  end

  describe "PATCH /me" do
    subject(:request) do
      patch "/me", authorization_header.merge(
        params: {
          user: {
            'name' => 'My Name'
          }
        }
      )
    end

    it "updates the profile of the current user" do
      request

      expect(response).to be_success
      expect(json['user']['name']).to eq('My Name')

      user.reload
      expect(user.name).to eq('My Name')
    end
  end
end
