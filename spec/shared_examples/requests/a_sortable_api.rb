require 'rails_helper'

RSpec.shared_examples "a sortable API" do |api_endpoint, test_data|
  let(:resource_collection_name) { test_data[:resource_collection_name] }
  let(:sortable_sample_set) { test_data[:sortable_sample_set] }

  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end

  it "returns all resource by the specified sorting" do
    sortable_sample_set.each_pair do |sort, first_value_data|
      get api_endpoint, api_authorization.merge(params: { "sort" => sort })

      expect(json[resource_collection_name].first[first_value_data.first]).to eq(first_value_data.last)
    end
  end
end
