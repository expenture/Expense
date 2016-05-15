class Me::AuthorizedOAuthApplicationsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @oauth_applications = OAuthApplication.authorized_for(current_user)
  end

  def destroy
    @oauth_application = OAuthApplication.authorized_for(current_user).find_by!(uid: params[:id])
    OAuthAccessToken.revoke_all_for @oauth_application, current_user
  end
end
