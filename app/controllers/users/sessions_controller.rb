class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    session[:user_sign_in_at] = Time.now.to_i

    self.resource = @user = warden.authenticate!(auth_options)
    sign_in @user

    # TODO: redirect to correct path
    redirect_to root_path
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  def show_current_user
    if current_user.present?
      render json: { current_user: { id: current_user.try(:id) } }
    else
      render json: { current_user: nil }
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end
end
