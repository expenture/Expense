require "rails_helper"

describe "User's Transaction Category Set Management API" do
  before(:all) do
    TransactionCategorySet.hash = {
      dpc: {
        name: "Default Parent Category",
        priority: 1,
        categories: {
          dc: {
            name: "Default Category",
            priority: 1
          }
        }
      }
    }
  end

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

  describe "GET /me/transaction_category_set" do
    context "user has no custom category set" do
      it "returns the default category set" do
        get '/me/transaction_category_set', authorization_header

        expect(response).to be_success
        expect(json).to have_key('transaction_category_set')
        expect(json['transaction_category_set']).to have_key('dpc')
        expect(json['transaction_category_set']['dpc']['categories']).to have_key('dc')
      end
    end

    context "user has custom category set" do
      before do
        tcs = TransactionCategorySet.new(user)
        @cs = {
          pc: {
            name: "Parent Category",
            priority: 2,
            categories: {
              c: {
                name: "Category",
                priority: 1
              }
            }
          }
        }
        tcs.hash = @cs
      end

      it "returns the user defined category set" do
        get '/me/transaction_category_set', authorization_header

        expect(response).to be_success
        expect(json).to have_key('transaction_category_set')
        expect(json['transaction_category_set']).to have_key('dpc')
        expect(json['transaction_category_set']['dpc']['categories']).to have_key('dc')
        expect(json['transaction_category_set']).to have_key('pc')
        expect(json['transaction_category_set']['pc']['categories']).to have_key('c')
      end
    end
  end

  describe "PUT /me/transaction_category_set" do
    it "updates the user's category set" do
      put '/me/transaction_category_set', authorization_header.merge(
        params: {
          transaction_category_set: {
            npc: {
              name: "New Parent Category",
              priority: 2,
              categories: {
                nc: {
                  name: "New Category",
                  priority: 1
                }
              }
            },
            npc2: {
              name: "New Parent Category 2",
              priority: 2,
              categories: {}
            }
          }
        }
      )

      expect(response).to be_success

      tcs = TransactionCategorySet.new(user)
      tcs_hash = tcs.hash

      expect(tcs_hash).to have_key('dpc')
      expect(tcs_hash['dpc']['categories']).to have_key('dc')
      expect(tcs_hash).to have_key('npc')
      expect(tcs_hash['npc']['categories']).to have_key('nc')
      expect(tcs_hash).to have_key('npc2')
    end
  end
end
