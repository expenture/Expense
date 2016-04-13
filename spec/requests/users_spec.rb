require "rails_helper"

describe "Users API" do
  describe "POST /users" do
    it "registers a new user" do
      post "/users", params: {
        user: {
          email: "someone@somewhere.com",
          password: "password",
          password_confirmation: "password"
        }
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to be_success
      expect(response.status).to eq(201)

      response_object = JSON.parse(response.body)
      expect(response_object['status']).to eq("confirmation_pending")

      confirmation_path = open_last_email.body.match(/users\/confirmation\?confirmation_token=[^"]+/)
      get "/#{confirmation_path}"
      expect(User.find_by(email: "someone@somewhere.com").confirmed_at).not_to be_blank
    end

    context "the unconfirmed user with same email already exists" do
      before do
        User.create!({
          email: "someone@somewhere.com",
          password: "password",
          password_confirmation: "password"
        })
      end

      it "recreates the new user and sends the confirmation email again" do
        post "/users", params: {
          user: {
            email: "someone@somewhere.com",
            password: "password",
            password_confirmation: "password"
          }
        }, headers: { 'Accept' => 'application/json' }

        expect(response).to be_success
        expect(response.status).to eq(201)

        response_object = JSON.parse(response.body)
        expect(response_object['status']).to eq("confirmation_pending")

        confirmation_path = open_last_email.body.match(/users\/confirmation\?confirmation_token=[^"]+/)
      end
    end

    context "a user with the same email already exists" do
      before do
        user = User.create!({
          email: "someone@somewhere.com",
          password: "password",
          password_confirmation: "password"
        })
        user.confirm
      end

      it "response a error with 400" do
        post "/users", params: {
          user: {
            email: "someone@somewhere.com",
            password: "password",
            password_confirmation: "password"
          }
        }, headers: { 'Accept' => 'application/json' }

        expect(response).not_to be_success
        expect(response.status).to eq(400)

        response_object = JSON.parse(response.body)
        expect(response_object['status']).to eq("error")
        expect(response_object).to have_key("error")
      end
    end
  end

  describe "POST /users/password" do
    subject(:request) do
      post "/users/password", params: {
        user: {
          email: "someone@somewhere.com"
        }
      }, headers: { 'Accept' => 'application/json' }
    end

    it "sends a reset password email to the user and responds with 200" do
      create(:user, :confirmed, email: 'someone@somewhere.com')
      subject

      expect(response.status).to eq(200)
      expect(open_last_email.body).to match(/reset_password_token/)
    end

    context "the user does not exists" do
      it "returns an error with 400" do
        subject

        expect(response.status).to eq(400)
        expect(json).to have_key('error')
      end
    end
  end
end
