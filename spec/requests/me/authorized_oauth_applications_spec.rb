require "rails_helper"

describe "User's Authorized Applications Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me/authorized_oauth_applications']
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

  describe "GET /me/authorized_oauth_applications" do
    it "responses a list of authorized oauth applications" do
      # authorize some oauth application
      oauth_application = create(:oauth_application)
      post "/oauth/token", params: {
        grant_type: :password,
        client_id: oauth_application.uid,
        client_secret: oauth_application.secret,
        username: user.email,
        password: user.password
      }
      post "/oauth/token", params: {
        grant_type: :password,
        client_uid: "14f93c7c-676e-465f-b1e2-360a901a04fa",
        client_type: "ios_device",
        client_name: "User's iPhone 5S",
        username: user.email,
        password: user.password
      }

      get '/me/authorized_oauth_applications', authorization_header
      expect(response).to be_success

      expect(json).to have_key('oauth_applications')
      expect(json['oauth_applications'].length).to eq(3) # including the app that we used to send the req, so it's 3, not 2

      expect_json_types 'oauth_applications.*', uid: :string,
                                                type: :string_or_null,
                                                name: :string
    end
  end

  describe "DELETE /me/authorized_oauth_applications/{oauth_application_uid}" do
    let(:oauth_application_to_be_revoked) { create(:oauth_application) }
    let(:another_oauth_application) { create(:oauth_application) }

    it "revokes authorization to the specified application" do
      # authorize the oauth applications
      post "/oauth/token", params: {
        grant_type: :password,
        client_id: oauth_application_to_be_revoked.uid,
        client_secret: oauth_application_to_be_revoked.secret,
        username: user.email,
        password: user.password
      }
      expect(response).to be_success
      token_to_be_revoked = json['access_token']
      post "/oauth/token", params: {
        grant_type: :password,
        client_id: another_oauth_application.uid,
        client_secret: another_oauth_application.secret,
        username: user.email,
        password: user.password
      }
      expect(response).to be_success
      token_not_to_be_revoked = json['access_token']

      get "/me/authorized_oauth_applications?access_token=#{token_to_be_revoked}"
      expect(response.status).to eq(200)

      get "/me/authorized_oauth_applications?access_token=#{token_not_to_be_revoked}"
      expect(response.status).to eq(200)

      delete "/me/authorized_oauth_applications/#{oauth_application_to_be_revoked.uid}", authorization_header
      expect(response).to be_success

      get "/me/authorized_oauth_applications?access_token=#{token_to_be_revoked}"
      expect(response.status).to eq(401)

      get "/me/authorized_oauth_applications?access_token=#{token_not_to_be_revoked}"
      expect(response.status).to eq(200)
    end

    context "the specified application is not authorized or does not exists" do
      it "responses an error with 404" do
        delete "/me/authorized_oauth_applications/#{oauth_application_to_be_revoked.uid}", authorization_header
        expect(response.status).to eq(404)

        delete "/me/authorized_oauth_applications/bla-bla-bla", authorization_header
        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /current_oauth_application" do
    it "revokes authorization upon the current oauth application" do
      delete "/current_oauth_application", authorization_header
      expect(response.status).to eq(200)
      delete "/current_oauth_application", authorization_header
      expect(response.status).to eq(401)
    end
  end
end
