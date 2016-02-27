require "rails_helper"

describe "Transactions Management API" do
  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let!(:account) { user.accounts.create!(uid: 'account_uid', name: "account") }
  let(:other_account) { user.accounts.create!(uid: 'other_account_uid', name: "other_account") }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  describe "GET /me/accounts/<account_uid>/transactions" do
    before do
      14.times do |i|
        if (i < 12)
          account.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        else
          other_account.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        end
      end
    end

    it_behaves_like "a paginatable API", "/me/accounts/account_uid/transactions", 12
    it_behaves_like "a filterable API", "/me/accounts/account_uid/transactions", 'transactions', 'amount',
                    {
                      'greater_then(8900000)' => [9000000],
                      'less_then_or_equal(2000000)' => [2000000, 1000000, 0, -1000000, -2000000],
                      'between(3000000,5000000)' => [3000000, 4000000, 5000000]
                    }
    it_behaves_like "a sortable API", "/me/accounts/account_uid/transactions", 'transactions',
                    {
                      '-amount' => ['amount', 9000000],
                      'amount' => ['amount', -2000000]
                    }

    it "sends a list of transactions" do
      get "/me/accounts/account_uid/transactions", api_authorization

      expect(response).to be_success
      expect(json).to have_key('transactions')
    end
  end

  describe "PUT /me/accounts/<account_uid>/transactions/<transaction_uid>" do
    let(:transaction_uid) { 'test_transaction_uid' }

    subject do
      put "/me/accounts/account_uid/transactions/#{transaction_uid}", api_authorization.merge({
        params: {
          transaction: {
            'amount' => -8_000_000
          }
        }
      })
    end

    context "the transaction does not exists" do
      it "creates a new transaction and returns 201" do
        subject

        expect(response).to be_success
        expect(response.status).to eq(201)

        transaction = account.transactions.find_by(uid: transaction_uid)

        expect(transaction.amount).to eq(-8_000_000)
      end
    end

    context "the transaction already exists" do
      before do
        account.transactions.create!(uid: transaction_uid, amount: 5_000_000)
      end

      it "replaces the account with new attributes and returns 200" do
        subject

        expect(response).to be_success
        expect(response.status).to eq(200)

        transaction = account.transactions.find_by(uid: transaction_uid)

        expect(transaction.amount).to eq(-8_000_000)
      end
    end

    context "with invalid params" do
      subject do
        put "/me/accounts/account_uid/transactions/#{transaction_uid}", api_authorization.merge({
          params: {
            transaction: {
              'amount' => nil
            }
          }
        })
      end

      it "returns an error with 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end

  describe "PATCH /me/accounts/<account_uid>/transactions/<transaction_uid>" do
    let(:transaction) do
      account.transactions.create!(uid: SecureRandom.uuid, amount: -5_000_000)
    end

    subject do
      patch "/me/accounts/account_uid/transactions/#{transaction.uid}", api_authorization.merge({
        params: {
          transaction: {
            'amount' => 8_000_000
          }
        }
      })
    end

    it "returns 200 and updates the account attributes" do
      subject

      expect(response).to be_success
      expect(response.status).to eq(200)

      transaction.reload

      expect(transaction.amount).to eq(8_000_000)
    end
  end

  describe "DELETE /me/accounts/<account_uid>/transactions/<transaction_uid>" do
    let(:transaction) do
      account.transactions.create!(uid: SecureRandom.uuid, amount: -5_000_000)
    end

    subject do
      delete "/me/accounts/account_uid/transactions/#{transaction.uid}", api_authorization
    end

    it "successfully destroys the specified transaction" do
      subject

      expect(response).to be_success

      expect(Transaction.find_by(uid: transaction.uid)).to be_nil
    end
  end
end
