require 'rails_helper'

RSpec.shared_examples "a paginatable API" do |api_endpoint, test_data|
  let(:resource_count) { test_data[:resource_count] }

  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  it "returns a pagination object" do
    get api_endpoint, api_authorization
    expect(json).to have_key('pagination')
  end

  it "returns item count in the pagination object" do
    get api_endpoint, api_authorization
    expect(json['pagination']['items_count']).to eq(resource_count)
  end

  it "returns page count in the pagination object" do
    get api_endpoint, api_authorization.merge(params: { per_page: 1 })
    expect(json['pagination']['pages_count']).to eq(resource_count)

    get api_endpoint, api_authorization.merge(params: { per_page: 2 })
    expect(json['pagination']['pages_count']).to eq((resource_count / 2 + 0.5).to_i)
  end
end
