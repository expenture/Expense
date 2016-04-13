class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    fb_access_token = request.env['omniauth.auth'].credentials.try(:token)
    @user = User.from_facebook_access_token(fb_access_token)

    if @user.present?
      session[:user_sign_in_at] = Time.now.to_i

      sign_in @user

      # TODO: redirect to correct path
      redirect_to root_path
    else
      flash[:alert] = "OAuth error"
      redirect_to new_user_session_path
    end
  end

  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # More info at:
  # https://github.com/plataformatec/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
