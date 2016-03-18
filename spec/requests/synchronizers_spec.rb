require "rails_helper"

describe "Synchronizers API" do
  describe "GET /synchronizers" do
    it "returns a list of available synchronizers" do
      get "/synchronizers"

      expect(response).to be_success
      expect_status(200)
      expect_json_types 'synchronizers.*', code: :string,
                                           region_code: :string,
                                           type: :string,
                                           name: :string,
                                           description: :string,
                                           passcodes: :object,
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
                                           }
    end
  end
end
