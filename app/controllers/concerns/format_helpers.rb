module FormatHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :camelize_keys, :time_format
  end

  def camelize_keys
    params[:camelize_keys]
  end

  def time_format
    params[:time_format]
  end
end
