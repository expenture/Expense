class PagesController < ApplicationController
  def index
    app_data = {
      expense: {
        app_name: Expense.app_name,
        app_url: Expense.app_url,
        default_locale: Expense.default_locale,
        version: Expense.version
      }
    }

    respond_to do |format|
      format.html do
        if ENV['INDEX_REDIRECT_URL'].present?
          redirect_to ENV['INDEX_REDIRECT_URL']
        else
          render json: app_data
        end
      end

      format.json do
        render json: app_data
      end
    end
  end
end
