class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  def new
    super
  end

  # POST /resource/confirmation
  def create
    super
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    super
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(_resource_name)
    flash[:success] = t('confirm_page.email_confirmed_you_can_now_sign_in', scope: :user)
    new_user_session_path
  end

  # The path used after confirmation.
  def after_confirmation_path_for(_resource_name, _resource)
    flash[:success] = t('confirm_page.email_confirmed_you_can_now_sign_in', scope: :user)
    new_user_session_path
  end
end
