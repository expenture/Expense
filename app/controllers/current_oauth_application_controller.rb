class CurrentOAuthApplicationController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def show
    @oauth_application = current_oauth_application
  end

  def update
    if current_user && current_oauth_application.owner != current_user
      @error = Error.new({
        status: 403,
        code: 'invalid_application_owner',
        message: "The current user isn't the owner of the current oauth application."
      })
      render template: :error, status: @error.status and return
    end

    @oauth_application = current_oauth_application

    @oauth_application.assign_attributes(oauth_application_params)

    if @oauth_application.save
      render status: status
    else
      @error = Error.new(@oauth_application.errors)
      render status: @error.status
    end
  end

  def destroy
    @oauth_application = current_oauth_application
    OAuthAccessToken.revoke_all_for @oauth_application, current_user
  end

  private

  def oauth_application_params
    params.require(:oauth_application).permit(:type, :name, :redirect_uri, :contact_code)
  end
end
