class ApplicationController < ActionController::Base
  protect_from_forgery
  include FormatHelpers

  before_action :timeout_user_session

  def timeout_user_session
    return if session[:user_sign_in_at].present? &&
              session[:user_sign_in_at] + 1.minute.to_i > Time.now.to_i
    sign_out :user
  end
end
