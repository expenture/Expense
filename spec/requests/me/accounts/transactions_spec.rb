require "rails_helper"

describe "User's Account Transaction Management API" do
  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let!(:account) { user.accounts.create!(uid: 'account_uid', name: "My Account") }
  let(:another_account) { user.accounts.create!(uid: 'another_account_uid', name: "My Another Account") }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  describe "GET /me/accounts/{account_uid}/transactions" do
    before do
      14.times do |i|
        if i < 12
          account.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        else
          another_account.transactions.create!(uid: SecureRandom.uuid, amount: (i - 2) * 1_000_000)
        end
      end
    end

    it_behaves_like "a paginatable API", "/me/accounts/account_uid/transactions",
                    resource_count: 12
    it_behaves_like "a filterable API", "/me/accounts/account_uid/transactions",
                    resource_collection_name: 'transactions',
                    filterable_attr_name: 'amount',
                    filterable_sample_set: {
                      'greater_then(8900000)' => [9000000],
                      'less_then_or_equal(2000000)' => [2000000, 1000000, 0, -1000000, -2000000],
                      'between(3000000,5000000)' => [3000000, 4000000, 5000000]
                    }
    it_behaves_like "a sortable API", "/me/accounts/account_uid/transactions",
                    resource_collection_name: 'transactions',
                    sortable_sample_set: {
                      '-amount' => ['amount', 9000000],
                      'amount' => ['amount', -2000000]
                    }

    it "sends a list of transactions" do
      get "/me/accounts/#{account.uid}/transactions", api_authorization

      expect(response).to be_success
      expect(json).to have_key('transactions')
    end
  end

  describe "PUT /me/accounts/{account_uid}/transactions/{transaction_uid}" do
    let(:transaction_uid) { 'test_transaction_uid' }

    subject do
      put "/me/accounts/#{account.uid}/transactions/#{transaction_uid}", api_authorization.merge(
        params: {
          transaction: {
            'amount' => -120_000,
            'description' => 'Fish And Chips',
            'category_code' => 'meal'
          }
        }
      )
    end

    context "the transaction does not exists" do
      it "creates a new transaction and returns 201" do
        subject

        expect(response).to be_success
        expect(response.status).to eq(201)

        transaction = account.transactions.find_by(uid: transaction_uid)
        expect(transaction).to be_on_record
        expect(transaction.amount).to eq(-120_000)
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
        expect(transaction).to be_on_record
        expect(transaction.amount).to eq(-120_000)
      end

      it "updates the TransactionCategorizationCase" do
        subject

        tcc = TransactionCategorizationCase.find_by(user: user, the_transaction: Transaction.last)
        expect(tcc).not_to be_blank
        expect(tcc.words).to include('Fish')
        expect(tcc.category_code).to eq('meal')
      end
    end

    context "with invalid params" do
      subject do
        put "/me/accounts/#{account.uid}/transactions/#{transaction_uid}", api_authorization.merge(
          params: {
            transaction: {
              'amount' => nil
            }
          }
        )
      end

      it "returns an error with 400" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end

    context "creating transactions on an syncing account" do
      let(:account) { create(:account, :syncing, user: user) }

      it "creates a not-on-record transaction and returns its data" do
        subject

        transaction = account.transactions.find_by(uid: transaction_uid)
        expect(transaction).not_to be_on_record

        expect(json['transaction']['on_record']).to eq(false)
      end
    end

    context "creating virtual transactions" do
      let(:separated_transaction) { account.transactions.create!(uid: SecureRandom.uuid, amount: 1_000_000) }
      subject do
        put "/me/accounts/#{account.uid}/transactions/#{transaction_uid}", api_authorization.merge(
          params: {
            transaction: {
              'separate_transaction_uid' => separated_transaction.uid,
              'amount' => -120_000,
              'description' => 'Fish And Chips',
              'category_code' => 'meal'
            }
          }
        )
      end

      it "returns the data of the virtual transaction" do
        subject
        expect(json['transaction']['separate_transaction_uid']).to eq(separated_transaction.uid)
        expect(json['transaction']['virtual']).to eq(true)
      end

      it "makes the separated transaction marked as separated" do
        expect(separated_transaction.separated).to eq(false)
        subject
        separated_transaction.reload
        expect(separated_transaction.separated).to eq(true)
      end

      it "makes the separated transaction to be ignore_in_statistics" do
        expect(separated_transaction.ignore_in_statistics).to eq(false)
        subject
        separated_transaction.reload
        expect(separated_transaction.ignore_in_statistics).to eq(true)
      end
    end
  end

  describe "PATCH /me/accounts/{account_uid}/transactions/{transaction_uid}" do
    let(:transaction) do
      account.transactions.create!(uid: SecureRandom.uuid, amount: -5_000_000)
    end

    subject do
      patch "/me/accounts/#{account.uid}/transactions/#{transaction.uid}", api_authorization.merge(
        params: {
          transaction: {
            'amount' => 120_000,
            'description' => 'Fish And Chips',
            'category_code' => 'meal'
          }
        }
      )
    end

    it "returns 200 and updates the transaction attributes" do
      subject

      expect(response).to be_success
      expect(response.status).to eq(200)

      transaction.reload

      expect(transaction.amount).to eq(120_000)
    end

    it "updates the TransactionCategorizationCase" do
      subject

      tcc = TransactionCategorizationCase.find_by(user: user, the_transaction: Transaction.last)
      expect(tcc).not_to be_blank
      expect(tcc.words).to include('Fish')
      expect(tcc.category_code).to eq('meal')
    end
  end

  describe "DELETE /me/accounts/{account_uid}/transactions/{transaction_uid}" do
    let(:transaction) do
      account.transactions.create!(uid: SecureRandom.uuid, amount: -5_000_000)
    end

    subject do
      delete "/me/accounts/#{account.uid}/transactions/#{transaction.uid}", api_authorization
    end

    it "successfully destroys the specified transaction" do
      subject

      expect(response).to be_success

      expect(Transaction.find_by(uid: transaction.uid)).to be_nil
    end

    context "the specified transaction is a synced transaction" do
      let(:account) { create(:syncing_account, user: user) }
      let(:transaction) do
        account.transactions.create!(uid: SecureRandom.uuid, amount: -5_000_000, on_record: true)
      end

      it "returns a error with status 400 and does not destroy the specified transaction" do
        subject

        expect(response).not_to be_success
        expect(response.status).to eq(400)

        expect(Transaction.find_by(uid: transaction.uid)).not_to be_blank
      end
    end
  end
end
