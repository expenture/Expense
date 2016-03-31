require "rails_helper"

describe "User's Account Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me/accounts']
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

  describe "GET /me/accounts" do
    before do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Other Account')
    end

    it "sends a list of accounts" do
      get '/me/accounts', authorization_header
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

  describe "PUT /me/accounts/{account_uid}" do
    let(:account_uid) { 'test_account_uid' }

    subject do
      put "/me/accounts/#{account_uid}", authorization_header.merge(
        params: {
          account: {
            'name' => 'Test New Account',
            'type' => 'custom_type',
            'currency' => 'USD',
            'balance' => 8_000_000
          }
        }
      )
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
        put "/me/accounts/#{account_uid}", authorization_header.merge(
          params: {
            account: {
              'name' => nil
            }
          }
        )
      end

      it "returns an error with status 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end

  describe "PATCH /me/accounts/{account_uid}" do
    let(:account) do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Account')
    end

    subject do
      patch "/me/accounts/#{account.uid}", authorization_header.merge(
        params: {
          account: {
            'name' => 'Test Account',
            'type' => 'custom_type',
            'currency' => 'USD',
            'balance' => 8_000_000
          }
        }
      )
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

  describe "DELETE /me/accounts/{account_uid}" do
    let(:account) do
      user.accounts.create!(uid: "#{user.id}-#{SecureRandom.uuid}", name: 'My Account')
    end

    subject do
      delete "/me/accounts/#{account.uid}", authorization_header
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

    context "destroying a syncing account" do
      let(:account) do
        create(:syncing_account, user: user)
      end

      it "returns an error with 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end

  describe "PUT /me/accounts/{account_uid}/transaction_categorization_suggestion" do
    subject do
      get "/me/accounts/#{user.accounts.last.uid}/transaction_categorization_suggestion", authorization_header.merge(
        params: {
          words: 'Sashimi rice bowl'
        }
      )
    end

    it "returns the suggested category code for some words" do
      subject

      expect(json).to have_key('category_code')
    end
  end

  describe "POST /me/accounts/{account_uid}/_clean" do
    before { allow(AccountOrganizingService).to receive(:clean) }
    let(:account) { create(:account, user: user) }

    it "runs cleaning on the account and returns 200" do
      post "/me/accounts/#{account.uid}/_clean", authorization_header

      expect(AccountOrganizingService).to have_received(:clean).once

      expect(response).to be_success
      expect(response.status).to eq(200)

      expect(json).to have_key('account')
      expect(json['account']['uid']).to eq(account.uid)
    end
  end

  describe "POST /me/accounts/{account_uid}/_merge?source_account_uid={source_account_uid}" do
    before { allow(AccountOrganizingService).to receive(:merge) }
    let(:source_account) { create(:account, user: user) }
    let(:target_account) { create(:account, user: user) }
    let(:other_account) { create(:account, user: user) }
    subject(:request) do
      post "/me/accounts/#{target_account.uid}/_merge", authorization_header.merge(
        params: {
          source_account_uid: source_account.uid
        }
      )
    end

    it "runs merging on the account and returns 200" do
      request

      expect(AccountOrganizingService).to have_received(:merge).once

      expect(response).to be_success
      expect(response.status).to eq(200)

      expect(json).to have_key('account')
      expect(json['account']['uid']).to eq(target_account.uid)
      expect(json).to have_key('source_account')
      expect(json['source_account']['uid']).to eq(source_account.uid)
    end

    it "updates any account identifier that is pointed to the source account to point to the target account for the user" do
      account_identifier = create(:account_identifier, user: user, account_uid: source_account.uid)
      expect(account_identifier.account_uid).to eq(source_account.uid)
      other_account_identifier = create(:account_identifier, user: user, account_uid: other_account.uid)
      expect(other_account_identifier.account_uid).to eq(other_account.uid)

      request
      account_identifier.reload
      other_account_identifier.reload

      expect(account_identifier.account_uid).to eq(target_account.uid)
      expect(other_account_identifier.account_uid).to eq(other_account.uid)
    end
  end
end
