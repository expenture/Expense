require "rails_helper"

describe "User's Accounts Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me/accounts']
  ]

  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }

  describe "GET /me/accounts" do
    before do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Other Account')
    end

    it "sends a list of accounts" do
      get '/me/accounts', {
        headers: {
          'Authorization' => "Bearer #{access_token.token}"
        }
      }

      expect(response).to be_success

      expect(json).to have_key('accounts')
      expect(json['accounts'].length).to eq(user.accounts.length)
      expect(json['accounts'].last['uid']).to be_a(String)
      expect(json['accounts'].last['type']).to be_a(String)
      expect(json['accounts'].last['name']).to be_a(String)
      expect(json['accounts'].last['currency']).to be_a(String)
      expect(json['accounts'].last['balance']).to be_a(Integer)
      expect(json['accounts'].last['default']).to be_in([true, false])
    end
  end

  describe "PUT /me/accounts/<account_uid>" do
    let(:account_uid) { 'test_account_uid' }

    subject do
      put "/me/accounts/#{account_uid}", {
        params: {
          account: {
            'name' => 'Test New Account',
            'type' => 'custom_type',
            'currency' => 'USD',
            'balance' => 8_000_000
          }
        },
        headers: {
          'Authorization' => "Bearer #{access_token.token}"
        }
      }
    end

    context "the account does not exists" do
      it "creates a new account for the user and returns 201" do
        subject

        expect(response).to be_success
        expect(response.status).to eq(201)

        account = user.accounts.find_by(uid: account_uid)

        expect(account.name).to eq('Test New Account')
        expect(account.type).to eq('custom_type')
        expect(account.currency).to eq('USD')
        expect(account.balance).to eq(8_000_000)
      end
    end

    context "the account already exists" do
      before do
        user.accounts.create!(uid: account_uid, name: 'Test Existing New Account')
      end

      it "replaces the account with new attributes and returns 200" do
        subject

        expect(response).to be_success
        expect(response.status).to eq(200)

        account = user.accounts.find_by(uid: account_uid)

        expect(account.name).to eq('Test New Account')
        expect(account.type).to eq('custom_type')
        expect(account.currency).to eq('USD')
        expect(account.balance).to eq(8_000_000)
      end
    end

    context "with invalid params" do
      subject do
        put "/me/accounts/#{account_uid}", {
          params: {
            account: {
              'name' => nil
            }
          },
          headers: {
            'Authorization' => "Bearer #{access_token.token}"
          }
        }
      end

      it "returns an error with 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end

  describe "PATCH /me/accounts/<account_uid>" do
    let(:account) do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Account')
    end

    subject do
      patch "/me/accounts/#{account.uid}", {
        params: {
          account: {
            'name' => 'Test Account',
            'type' => 'custom_type',
            'currency' => 'USD',
            'balance' => 8_000_000
          }
        },
        headers: {
          'Authorization' => "Bearer #{access_token.token}"
        }
      }
    end

    it "returns 200 and updates the account attributes" do
      subject

      expect(response).to be_success
      expect(response.status).to eq(200)

      account.reload

      expect(account.name).to eq('Test Account')
      expect(account.type).to eq('custom_type')
      expect(account.currency).to eq('USD')
      expect(account.balance).to eq(8_000_000)
    end
  end

  describe "DELETE /me/accounts/<account_uid>" do
    let(:account) do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Account')
    end

    subject do
      delete "/me/accounts/#{account.uid}", {
        headers: {
          'Authorization' => "Bearer #{access_token.token}"
        }
      }
    end

    it "successfully destroys the specified account" do
      subject

      expect(response).to be_success

      expect(Account.find_by(uid: account.uid)).to be_nil
    end

    context "destroying a default account" do
      let(:account) do
        user.default_account
      end

      it "returns an error with 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end

  describe "PUT /me/accounts/<account_uid>/transaction_categorization_suggestion" do
    subject do
      get "/me/accounts/#{user.accounts.last.uid}/transaction_categorization_suggestion", {
        headers: {
          'Authorization' => "Bearer #{access_token.token}"
        },
        params: {
          words: 'Sashimi rice bowl'
        }
      }
    end

    it "returns the suggested category code for some words" do
      subject

      expect(json).to have_key('category_code')
    end
  end
end
