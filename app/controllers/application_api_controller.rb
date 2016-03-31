class ApplicationAPIController < ActionController::API
  include APIHelper::Paginatable
  include APIHelper::Sortable
  include APIHelper::Filterable

  rescue_from StandardError, with: :render_error

  helper_method :current_user, :camelize_keys, :time_format

  def current_user
    @current_user ||= doorkeeper_token && User.find(doorkeeper_token.resource_owner_id)
  end

  def camelize_keys
    params[:camelize_keys]
  end

  def time_format
    params[:time_format]
  end

  def render_error(e)
    @error = Error.new(e)
    render template: :error, status: @error.status
    raise e if @error.status == 500
  end
end
