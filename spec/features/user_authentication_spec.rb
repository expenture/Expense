require 'rails_helper'

feature "User Authentication", type: :feature do
  feature "User Registration" do
    scenario "User Registration With Email" do
      host = default_url_options[:host]
      ENV['APP_URL'] = "http://#{host}"

      page.driver.post "/users", {
        user: {
          email: "someone@somewhere.com",
          password: "password",
          password_confirmation: "password"
        }
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(page.driver.status_code).to eq(201)

      page.driver.post "/oauth/token", {
        grant_type: :password,
        username: "someone@somewhere.com",
        password: "password"
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(page.driver.status_code).to eq(401)

      confirmation_path = open_last_email.body.match(%r{/users/confirmation\?confirmation_token=[^ "]+})[0]

      visit confirmation_path

      page.driver.post "/oauth/token", {
        grant_type: :password,
        username: "someone@somewhere.com",
        password: "password"
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(page.driver.status_code).to eq(200)
    end
  end
end
