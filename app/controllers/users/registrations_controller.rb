class Users::RegistrationsController < Devise::RegistrationsController
# before_action :configure_sign_up_params, only: [:create]
# before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    existing_unconfirmed_user = User.find_by(email: resource.email, confirmed_at: nil)
    existing_unconfirmed_user.destroy if existing_unconfirmed_user

    resource.save

    respond_to do |format|
      format.html do
        if resource.persisted?
          sign_up(resource_name, resource)
          flash[:notice] = t('sign_up_page.confirmation_instructions_sent', scope: :user)
        else
          clean_up_passwords resource
          set_minimum_password_length
          respond_with resource
        end
      end
      format.json do
        if resource.persisted?
          render status: 201
        else
          @error = Error.new(@user.errors)
          render status: @error.status
        end
      end
    end
  end

  # GET /resource/edit
  def edit
    nil
  end

  # PUT /resource
  def update
    nil
  end

  # DELETE /resource
  def destroy
    nil
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    nil
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end
