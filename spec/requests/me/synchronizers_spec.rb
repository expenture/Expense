require "rails_helper"

describe "User's Synchronizer Management API" do
  it_behaves_like "requiring a valid access token", [
    [:get, '/me/synchronizers']
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

  describe "GET /me/synchronizers" do
    before do
      syncer = TWEInvoiceSyncer.new(user: user, uid: SecureRandom.uuid, name: 'My Syncer', passcode_1: '0987654321', passcode_2: 'passcode_2')
      syncer.save!
    end

    it "returns a list of synchronizers" do
      get '/me/synchronizers', authorization_header

      expect(response).to be_success
      expect_status(200)
      expect_json_types 'synchronizers.*', user_id: :integer,
                                           uid: :string,
                                           type: :string,
                                           enabled: :boolean,
                                           schedule: :string,
                                           name: :string,
                                           status: :string,
                                           email_endpoint: :string_or_null
    end
  end

  describe "PUT /me/synchronizers/{synchronizer_uid}" do
    let(:synchronizer_uid) { SecureRandom.uuid }
    subject(:request) do
      put "/me/synchronizers/#{synchronizer_uid}", authorization_header.merge(
        params: {
          synchronizer: {
            name: 'My Synchronizer',
            type: 'tw_einvoice',
            passcode_1: '0987654321',
            passcode_2: 'abc123'
          }
        }
      )
    end

    context "no synchronizer with the matching uid exists" do
      it "creates a new synchronizer and returns its data with 201" do
        request

        expect_status(201)

        new_synchronizer = Synchronizer.last
        expect(new_synchronizer.class).to eq(TWEInvoiceSyncer)
        expect(new_synchronizer.user).to eq(user)
        expect(new_synchronizer.name).to eq('My Synchronizer')

        expect_json_types 'synchronizer', user_id: :integer,
                                          uid: :string,
                                          type: :string,
                                          enabled: :boolean,
                                          schedule: :string,
                                          name: :string,
                                          status: :string
      end
    end

    context "a synchronizer with the matching uid exists" do
      before do
        syncer = TWEInvoiceSyncer.new(user: user, uid: synchronizer_uid, name: 'My Old Syncer', passcode_1: '0900000000', passcode_2: 'pass')
        syncer.save!
      end

      it "replaces the synchronizer with the given attrs and returns the new data with 200" do
        request

        expect_status(200)

        synchronizer = Synchronizer.last
        expect(synchronizer.class).to eq(TWEInvoiceSyncer)
        expect(synchronizer.user).to eq(user)
        expect(synchronizer.name).to eq('My Synchronizer')
        expect(synchronizer.passcode_1).to eq('0987654321')
        expect(synchronizer.passcode_2).to eq('abc123')

        expect_json_types 'synchronizer', user_id: :integer,
                                          uid: :string,
                                          type: :string,
                                          enabled: :boolean,
                                          schedule: :string,
                                          name: :string,
                                          status: :string
      end
    end

    context "bad request with a invalid type" do
      subject(:request) do
        put "/me/synchronizers/#{synchronizer_uid}", authorization_header.merge(
          params: {
            synchronizer: {
              name: 'My Synchronizer',
              type: 'invalid_invalid_invalid', # invalid
              passcode_1: '0987654321',
              passcode_2: 'abc123'
            }
          }
        )
      end

      it "returns an error with code 'bad_attributes' and status 400" do
        request
        expect_status(400)
        expect_json_types 'error', status: :integer,
                                   code: :string,
                                   message: :string
        expect(json['error']['code']).to eq('bad_attributes')
      end
    end

    context "bad request with missing the type param" do
      subject(:request) do
        put "/me/synchronizers/#{synchronizer_uid}", authorization_header.merge(
          params: {
            synchronizer: {
              name: 'My Synchronizer',
              # type: is missing!
              passcode_1: 'aaaaaa',
              passcode_2: 'abc123'
            }
          }
        )
      end

      it "returns an error with code 'bad_attributes' and status 400" do
        request
        expect_status(400)
        expect_json_types 'error', status: :integer,
                                   code: :string,
                                   message: :string
        expect(json['error']['code']).to eq('bad_attributes')
      end
    end

    context "bad request with invalid passcodes" do
      subject(:request) do
        put "/me/synchronizers/#{synchronizer_uid}", authorization_header.merge(
          params: {
            synchronizer: {
              name: 'My Synchronizer',
              type: 'tw_einvoice',
              passcode_1: 'aaaaaa', # invalid
              passcode_2: 'abc123'
            }
          }
        )
      end

      it "returns an error with code 'bad_attributes' and status 400" do
        request
        expect_status(400)
        expect_json_types 'error', status: :integer,
                                   code: :string,
                                   message: :string
        expect(json['error']['code']).to eq('bad_attributes')
      end
    end
  end

  describe "PATCH /me/synchronizers/{synchronizer_uid}" do
    let(:synchronizer_uid) { SecureRandom.uuid }
    let!(:syncer) do
      syncer = TWEInvoiceSyncer.new(user: user, uid: synchronizer_uid, name: 'My Syncer', passcode_1: '0987654321', passcode_2: 'passcode_2')
      syncer.save!
      syncer
    end

    subject(:request) do
      patch "/me/synchronizers/#{synchronizer_uid}", authorization_header.merge(
        params: {
          synchronizer: {
            name: 'My Awesone Syncer',
            schedule: 'high_frequency',
            type: 'another_type' # unpermitted attribute
          }
        }
      )
    end

    it "updates the existing syncer with the given attributes and returns the new data" do
      request
      syncer.reload

      expect(syncer.name).to eq('My Awesone Syncer')
      expect(syncer.schedule).to eq('high_frequency')

      expect(json['synchronizer']['name']).to eq('My Awesone Syncer')
      expect(json['synchronizer']['schedule']).to eq('high_frequency')
    end

    it "ignores any unpermitted attribute and returns the new data" do
      request
      syncer.reload

      expect(syncer.type).to eq('tw_einvoice')

      expect(json['synchronizer']['type']).to eq('tw_einvoice')
    end

    context "a synchronizer with the specified uid doesn't exists" do
      subject(:request) do
        patch "/me/synchronizers/not_exixts", authorization_header.merge(
          params: {
            synchronizer: {
              name: 'My Awesone Syncer',
              type: 'another_type' # unpermitted attribute
            }
          }
        )
      end

      it "returns an error with code 'not_found' and status 404" do
        request
        expect_status(404)
        expect_json_types 'error', status: :integer,
                                   code: :string,
                                   message: :string
        expect(json['error']['code']).to eq('not_found')
      end
    end
  end
end
