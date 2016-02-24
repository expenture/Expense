require 'rails_helper'

RSpec.shared_examples "requiring a valid access token" do |sample_requests|
  let(:access_token) { create(:oauth_access_token) }

  context "using a valid access token" do
    it "returns to be success" do
      sample_requests.each do |sample_request|
        send(
          sample_request[0],
          sample_request[1],
          (sample_request[2] || {}).merge({
            headers: (sample_request[2] && sample_request[2][:headers] || {}).merge({
              'Authorization' => "Bearer #{access_token.token}"
            })
          })
        )

        expect(response).to be_success
      end
    end
  end

  context "not using an access token" do
    it "returns to be unsuccess with status code 401" do
      sample_requests.each do |sample_request|
        send(
          sample_request[0],
          sample_request[1],
          sample_request[2]
        )

        expect(response).not_to be_success
        expect(response.status).to eq(401)
      end
    end
  end

  context "using a invalid access token" do
    it "returns to be unsuccess with status code 401" do
      sample_requests.each do |sample_request|
        send(
          sample_request[0],
          sample_request[1],
          (sample_request[2] || {}).merge({
            headers: (sample_request[2] && sample_request[2][:headers] || {}).merge({
              'Authorization' => "Bearer wrong_token"
            })
          })
        )

        # byebug

        expect(response).not_to be_success
        expect(response.status).to eq(401)
      end
    end
  end

  context "using a expired access token" do
    it "returns to be unsuccess with status code 401" do
      access_token.token
      Timecop.travel 14.days.from_now

      sample_requests.each do |sample_request|
        send(
          sample_request[0],
          sample_request[1],
          (sample_request[2] || {}).merge({
            headers: (sample_request[2] && sample_request[2][:headers] || {}).merge({
              'Authorization' => "Bearer #{access_token.token}"
            })
          })
        )

        expect(response).not_to be_success
        expect(response.status).to eq(401)

        Timecop.return
      end
    end
  end
end
