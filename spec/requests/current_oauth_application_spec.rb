require "rails_helper"

describe "Current OAuth Application Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/current_oauth_application']
  ]

  let(:user) { create(:user, :confirmed) }
  let(:oauth_application) { create(:oauth_application, owner: user) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id, oauth_application: oauth_application) }
  let(:authorization_header) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  describe "GET /current_oauth_application" do
    it "responds with the information of the current oauth application" do
      get '/current_oauth_application', authorization_header
      expect(response).to be_success
      expect_json_types 'oauth_application', uid: :string,
                                             type: :string_or_null,
                                             name: :string
    end
  end

  describe "PATCH /current_oauth_application" do
    subject(:request) do
      patch "/current_oauth_application", authorization_header.merge(
        params: {
          oauth_application: {
            'name' => "My iPhone 5S",
            'type' => 'ios_device',
            'contact_code' => 'dd010fac304ca246'
          }
        }
      )
    end

    it "updates the information of the current oauth application" do
      request

      expect(response).to be_success
      expect(json['oauth_application']['name']).to eq("My iPhone 5S")
      expect(json['oauth_application']['type']).to eq('ios_device')

      oauth_application.reload
      expect(oauth_application.contact_code).to eq('dd010fac304ca246')
    end

    context "the current oauth application does not belongs to the current user" do
      let(:oauth_application) { create(:oauth_application) }

      it "responds an error with 403" do
        request

        expect(json).to have_key('error')
        expect(response.status).to eq(403)

        oauth_application.reload
        expect(oauth_application.contact_code).to be_nil
      end
    end
  end
end
