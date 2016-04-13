require 'rails_helper'

feature "User Authentication", type: :feature do
  feature "User Registration" do
    scenario "User Registration With Email" do
      host = default_url_options[:host]
      ENV['APP_URL'] = "http://#{host}"

      visit new_user_registration_path

      fill_in(:user_email, with: 'someone@somewhere.com')
      fill_in(:user_password, with: 'password')
      fill_in(:user_password_confirmation, with: 'password')
      first('input[type="submit"]').click

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

  feature "User Sign In" do
    scenario "User Sign In With Email And Password" do
      create(:user, :confirmed, email: 'email@user.com', password: 'password')

      visit new_user_session_path

      fill_in(:user_email, with: 'email@user.com')
      fill_in(:user_password, with: 'password')
      first('input[type="submit"]').click

      visit users_sessions_current_user_path
      expect(JSON.parse(page.body)['current_user']).to be_present

      Timecop.freeze(12.seconds.from_now)
      visit users_sessions_current_user_path
      expect(JSON.parse(page.body)['current_user']).to be_present

      # The session only last for 1 minute
      Timecop.freeze(62.seconds.from_now)
      visit users_sessions_current_user_path
      expect(JSON.parse(page.body)['current_user']).not_to be_present

      Timecop.return
    end

    scenario "User Sign In With Facebook" do
      ENV['FB_APP_ID'] = 'test_id'
      OmniAuth.config.test_mode = true
      FacebookService.mock_mode = true
      visit new_user_session_path
      find('#sign-in-with-facebook-link').click
    end
  end
end
