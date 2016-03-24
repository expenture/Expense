require "rails_helper"

describe "User's Account Identifier Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me/account_identifiers']
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

  describe "GET /me/account_identifiers" do
    before do
      create(:account_identifier, user: user)
      create(:account_identifier, user: user)
    end

    it "retruns a list of account identifiers" do
      get '/me/account_identifiers', authorization_header
      expect(response).to be_success
      expect_json_types 'account_identifiers.*', id: :integer,
                                                 type: :string_or_null,
                                                 identifier: :string,
                                                 account_uid: :string_or_null,
                                                 sample_transaction_party_name: :string_or_null,
                                                 sample_transaction_description: :string_or_null,
                                                 sample_transaction_amount: :string_or_null,
                                                 sample_transaction_datetime: :string_or_null
    end
  end

  describe "PATCH /me/account_identifiers/{id}" do
    let(:account_identifier) { create(:account_identifier, user: user) }

    it "sets the new account_uid and retruns the new data" do
      account = user.accounts.first

      patch "/me/account_identifiers/#{account_identifier.id}", authorization_header.merge(
        params: {
          account_identifier: {
            account_uid: account.uid
          }
        }
      )

      expect(response).to be_success
      expect(response.status).to eq(200)

      account_identifier.reload
      expect(account_identifier.account_uid).to eq(account.uid)

      expect(json['account_identifier']['account_uid']).to eq(account.uid)
    end

    context "sets the account_uid to an non-existing account" do
      it "remains the account identifier unchanged and retruns an error with status code 400" do
        patch "/me/account_identifiers/#{account_identifier.id}", authorization_header.merge(
          params: {
            account_identifier: {
              account_uid: 'non-existing_account_uid'
            }
          }
        )

        expect(response).not_to be_success
        expect(response.status).to eq(400)

        account_identifier.reload
        expect(account_identifier.account_uid).to be_nil

        expect(json['account_identifier']['errors']).to have_key('account_uid')
      end
    end

    context "sets the account_uid to an account that belongs to another user" do
      it "remains the account identifier unchanged and retruns an error with status code 400" do
        patch "/me/account_identifiers/#{account_identifier.id}", authorization_header.merge(
          params: {
            account_identifier: {
              account_uid: create(:account).uid
            }
          }
        )

        expect(response).not_to be_success
        expect(response.status).to eq(400)

        account_identifier.reload
        expect(account_identifier.account_uid).to be_nil

        expect(json['account_identifier']['errors']).to have_key('account_uid')
      end
    end

    context "changing another user's account identifier" do
      let(:account_identifier) { create(:account_identifier) }

      it "remains the account identifier unchanged and retruns an error with status code 404" do
        patch "/me/account_identifiers/#{account_identifier.id}", authorization_header.merge(
          params: {
            account_identifier: {
              account_uid: create(:account).uid
            }
          }
        )

        expect(response).not_to be_success
        expect(response.status).to eq(404)

        account_identifier.reload
        expect(account_identifier.account_uid).to be_nil
      end
    end
  end
end
