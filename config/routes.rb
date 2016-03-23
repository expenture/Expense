Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users, only: [:sessions, :confirmations, :unlocks]

  resources :users, defaults: { format: :json }

  namespace :me, defaults: { format: :json } do
    resources :accounts, only: [:index, :update, :destroy] do
      get :transaction_categorization_suggestion, to: 'accounts#transaction_categorization_suggestion'
      resources :transactions, controller: 'accounts/transactions',
                               only: [:index, :update, :destroy]
    end
    resource :transaction_category_set, controller: 'transaction_category_set',
                                        only: [:show, :update]
    resources :transactions, only: [:index]
    resources :synchronizers, only: [:index, :update, :destroy],
                              defaults: { format: :json }
  end

  resources :synchronizers, only: [:index], defaults: { format: :json }

  namespace :webhook_endpoints, defaults: { format: :json } do
    namespace :syncer_receiving, defaults: { format: :json } do
      post 'mailgun', to: 'emails#mailgun_receive'
    end
  end

  # Sidekiq
  require 'sidekiq/web'
  Sidekiq::Web.use(Rack::Session::Cookie, secret: Rails.application.config.secret_token)
  Sidekiq::Web.instance_eval { @middleware.reverse! }
  Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
    ENV['ADMIN_USERNAME'].present? && ENV['ADMIN_PASSWORD'].present? &&
      username == ENV['ADMIN_USERNAME'] &&
      password == ENV['ADMIN_PASSWORD']
  end
  mount Sidekiq::Web => '/jobs'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
