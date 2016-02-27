class ApplicationAPIController < ActionController::API
  include APIHelper::Paginatable
  include APIHelper::Sortable
  include APIHelper::Filterable

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
end
