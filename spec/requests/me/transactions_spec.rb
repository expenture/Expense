require "rails_helper"

describe "User's Transactions Listing API" do
  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  it_behaves_like "requiring a valid access token", [
    [:get, '/me/accounts']
  ]

  describe "GET /me/transactions" do
    before do
      user.accounts.create!(uid: SecureRandom.uuid, name: "next")

      12.times do |i|
        if i < 5
          user.accounts.first.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        else
          user.accounts.last.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        end
      end
    end

    it_behaves_like "a paginatable API", "/me/transactions",
                    resource_count: 12
    it_behaves_like "a filterable API", "/me/transactions",
                    resource_collection_name: 'transactions',
                    filterable_attr_name: 'amount',
                    filterable_sample_set: {
                      'greater_then(8900000)' => [9000000],
                      'less_then_or_equal(2000000)' => [2000000, 1000000, 0, -1000000, -2000000],
                      'between(3000000,5000000)' => [3000000, 4000000, 5000000]
                    }
    it_behaves_like "a sortable API", "/me/transactions",
                    resource_collection_name: 'transactions',
                    sortable_sample_set: {
                      '-amount' => ['amount', 9000000],
                      'amount' => ['amount', -2000000]
                    }

    it "sends a list of transactions" do
      get '/me/transactions', api_authorization

      expect(response).to be_success
      expect(json).to have_key('transactions')
    end
  end
end
