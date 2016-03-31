require "rails_helper"

describe "Synchronizer Types API" do
  describe "GET /synchronizer_types" do
    it "returns a list of available synchronizer types" do
      get "/synchronizer_types"

      expect(response).to be_success
      expect_status(200)
      expect_json_types 'synchronizer_types.*', code: :string,
                                                region_code: :string_or_null,
                                                type: :string_or_null,
                                                collect_methods: :array_of_strings,
                                                name: :string,
                                                description: :string,
                                                introduction: :string,
                                                schedules: {
                                                  normal: {
                                                    description: :string,
                                                    times: :array
                                                  },
                                                  high_frequency: {
                                                    description: :string,
                                                    times: :array
                                                  },
                                                  low_frequency: {
                                                    description: :string,
                                                    times: :array
                                                  }
                                                },
                                                passcodes: :object,
                                                email_endpoint_host: :string_or_null,
                                                email_endpoint_introduction: :string_or_null
    end
  end
end
