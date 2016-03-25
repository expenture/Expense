require 'rails_helper'

RSpec.shared_examples "a filterable API" do |api_endpoint, test_data|
  let(:resource_collection_name) { test_data[:resource_collection_name] }
  let(:filterable_attr_name) { test_data[:filterable_attr_name] }
  let(:filterable_sample_set) { test_data[:filterable_sample_set] }

  let(:user) { create(:user, :confirmed) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: user.id) }
  let(:api_authorization) do
    {
      headers: {
        'Authorization' => "Bearer #{access_token.token}"
      }
    }
  end
  let(:sample_values) { filterable_sample_set.values.reduce { |a, e| a.concat(e) } }

  it "returns all resource if no filter is specified" do
    get api_endpoint, api_authorization

    values = json[resource_collection_name].map { |r| r[filterable_attr_name] }

    expect(values).to include(*sample_values)
  end

  it "returns filtered resource if a filter is specified" do
    filterable_sample_set.each_pair do |filter, sample_values|
      get api_endpoint, api_authorization.merge(params: { "filter[#{filterable_attr_name}]" => filter })

      json[resource_collection_name].each do |resource|
        expect(sample_values).to include(resource[filterable_attr_name])
      end
    end
  end
end
