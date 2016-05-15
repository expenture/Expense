require "rails_helper"

describe "Resource Owner Password Credentials Grant Flow and access token refreshing" do
  describe "POST /oauth/token" do
    let(:client) { create(:oauth_application) }

    context "using email and password as credentials" do
      let(:user) { create(:user, :confirmed) }

      it "returns an access token with refresh token" do
        post "/oauth/token", params: {
          grant_type: :password,
          client_id: client.uid,
          client_secret: client.secret,
          username: user.email,
          password: user.password
        }

        expect(response).to be_success

        response_object = JSON.parse(response.body)

        expect(response_object).to have_key('access_token')
        expect(response_object).to have_key('refresh_token')
      end

      context "specifying the client without credentials" do
        it "creates the oauth application under the current user and returns an access token with refresh token" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_uid: "14f93c7c-676e-465f-b1e2-360a901a04fa",
            client_type: "ios_device",
            client_name: "User's iPhone 5S",
            username: user.email,
            password: user.password
          }

          expect(response).to be_success

          new_oauth_application = OAuthApplication.last
          expect(OAuthAccessToken.last.oauth_application).to eq(new_oauth_application)
          expect(new_oauth_application.owner).to eq(user)
          expect(new_oauth_application.uid).to eq('14f93c7c-676e-465f-b1e2-360a901a04fa')
          expect(new_oauth_application.type).to eq('ios_device')
          expect(new_oauth_application.name).to eq('User\'s iPhone 5S')

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('access_token')
          expect(response_object).to have_key('refresh_token')
        end

        context "the application uid is already created under the same user" do
          it "uses the existing oauth application and returns an access token with refresh token" do
            create(:oauth_application, uid: '14f93c7c-676e-465f-b1e2-360a901a04fa', owner: user, name: 'User\'s iPhone 7')

            post "/oauth/token", params: {
              grant_type: :password,
              client_uid: "14f93c7c-676e-465f-b1e2-360a901a04fa",
              client_type: "ios_device",
              client_name: "User's iPhone 5S",
              username: user.email,
              password: user.password
            }

            expect(response).to be_success

            new_oauth_application = OAuthApplication.last
            expect(OAuthAccessToken.last.oauth_application).to eq(new_oauth_application)
            expect(new_oauth_application.uid).to eq('14f93c7c-676e-465f-b1e2-360a901a04fa')
            expect(new_oauth_application.name).to eq('User\'s iPhone 7')

            response_object = JSON.parse(response.body)

            expect(response_object).to have_key('access_token')
            expect(response_object).to have_key('refresh_token')
          end
        end

        context "the application uid is already used by another application under another user" do
          it "response a error" do
            # Same uid, another user's application
            create(:oauth_application, uid: '14f93c7c-676e-465f-b1e2-360a901a04fa')

            post "/oauth/token", params: {
              grant_type: :password,
              client_uid: "14f93c7c-676e-465f-b1e2-360a901a04fa",
              client_type: "ios_device",
              client_name: "User's iPhone 5S",
              username: user.email,
              password: user.password
            }

            expect(response).not_to be_success

            response_object = JSON.parse(response.body)

            expect(response_object).to have_key('error')
            expect(response_object).not_to have_key('access_token')
            expect(response_object).not_to have_key('refresh_token')
          end
        end
      end

      context "not providing client credentials" do
        it "response a error" do
          post "/oauth/token", params: {
            grant_type: :password,
            username: user.email,
            password: user.password
          }

          expect(response).not_to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('error')
          expect(response_object).not_to have_key('access_token')
          expect(response_object).not_to have_key('refresh_token')
        end
      end

      context "using invalid client credentials" do
        it "response a error" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_id: client.uid,
            client_secret: 'wrong_client_secret',
            username: user.email,
            password: user.password
          }

          expect(response).not_to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('error')
          expect(response_object).not_to have_key('access_token')
          expect(response_object).not_to have_key('refresh_token')
        end
      end

      context "using a wrong password" do
        it "response a error" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_id: client.uid,
            client_secret: client.secret,
            username: user.email,
            password: 'wrong_password'
          }

          expect(response).not_to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('error')
          expect(response_object).not_to have_key('access_token')
          expect(response_object).not_to have_key('refresh_token')
        end

        context "using a wrong password for more then 20 times" do
          before do
            # many failed attempts
            21.times do
              post "/oauth/token", params: {
                grant_type: :password,
                client_id: client.uid,
                client_secret: client.secret,
                username: user.email,
                password: 'wrong_password'
              }
            end
          end

          it "locks the user" do
            # a correct login
            post "/oauth/token", params: {
              grant_type: :password,
              username: user.email,
              password: user.password
            }

            # but the user is already locked
            expect(response).not_to be_success

            response_object = JSON.parse(response.body)

            expect(response_object).to have_key('error')
            expect(response_object).not_to have_key('access_token')
            expect(response_object).not_to have_key('refresh_token')
          end

          context "after three hours passed" do
            before { Timecop.travel 3.hours.from_now }
            after  { Timecop.return }

            it "unlocks the user for login" do
              post "/oauth/token", params: {
                grant_type: :password,
                client_id: client.uid,
                client_secret: client.secret,
                username: user.email,
                password: user.password
              }

              expect(response).to be_success

              response_object = JSON.parse(response.body)

              expect(response_object).to have_key('access_token')
              expect(response_object).to have_key('refresh_token')
            end
          end
        end
      end
    end

    context "using Facebook access token as credentials" do
      before do
        FacebookService.mock_mode = true
      end

      context "for a new user" do
        let(:fb_access_token) do
          # set the mock app id: pass it in as the access token
          FacebookService.app_id
        end

        it "returns an access token with refresh token" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_id: client.uid,
            client_secret: client.secret,
            username: 'facebook:access_token',
            password: fb_access_token
          }

          expect(response).to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('access_token')
          expect(response_object).to have_key('refresh_token')
        end
      end

      context "for a existing user with the matching email" do
        let(:fb_access_token) do
          # set the mock app id: pass it in as the access token
          FacebookService.app_id
        end
        before do
          create(:user, email: FacebookService.user_data_from_facebook_access_token(fb_access_token)[:email])
        end

        it "returns an access token with refresh token" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_id: client.uid,
            client_secret: client.secret,
            username: 'facebook:access_token',
            password: fb_access_token
          }

          expect(response).to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('access_token')
          expect(response_object).to have_key('refresh_token')
        end
      end

      context "using an Facebook access token for another app" do
        let(:fb_access_token) do
          # set the mock app id: pass it in as the access token
          'some_other_id'
        end

        it "rejects to issue an access token" do
          post "/oauth/token", params: {
            grant_type: :password,
            client_id: client.uid,
            client_secret: client.secret,
            username: 'facebook:access_token',
            password: fb_access_token
          }

          expect(response).not_to be_success

          response_object = JSON.parse(response.body)

          expect(response_object).to have_key('error')
          expect(response_object).not_to have_key('access_token')
          expect(response_object).not_to have_key('refresh_token')
        end
      end
    end

    context "using refresh token" do
      let(:user) { create(:user, :confirmed) }

      it "issues a new access token" do
        post "/oauth/token", params: {
          grant_type: :password,
          client_id: client.uid,
          client_secret: client.secret,
          username: user.email,
          password: user.password
        }

        response_object = JSON.parse(response.body)

        refresh_token = response_object['refresh_token']

        post "/oauth/token", params: {
          grant_type: :refresh_token,
          refresh_token: refresh_token
        }

        expect(response).to be_success

        response_object = JSON.parse(response.body)

        expect(response_object).to have_key('access_token')
        expect(response_object).to have_key('refresh_token')
      end
    end
  end
end
