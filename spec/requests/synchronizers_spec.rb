require "rails_helper"

describe "Synchronizers API" do
  describe "GET /synchronizers" do
    it "returns a list of available synchronizers" do
      get "/synchronizers"

      expect(response).to be_success
      expect_status(200)
      expect_json_types 'synchronizers.*', code: :string,
                                           region_code: :string_or_null,
                                           type: :string_or_null,
                                           collect_methods: :array_of_strings,
                                           name: :string,
                                           description: :string,
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
