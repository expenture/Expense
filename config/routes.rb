Rails.application.routes.draw do
  root to: 'pages#index'
  get :index, to: 'pages#index'

  use_doorkeeper

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get 'users/sessions/current_user', to: 'users/sessions#show_current_user'
  end

  resource :current_oauth_application, only: [:show, :update, :destroy], defaults: { format: :json }

  namespace :me, defaults: { format: :json } do
    resources :authorized_oauth_applications, only: [:index, :destroy]

    resources :accounts, only: [:index, :update, :destroy] do
      post :_clean, to: 'accounts#clean'
      post :_merge, to: 'accounts#merge'
      get :transaction_categorization_suggestion, to: 'accounts#transaction_categorization_suggestion'
      resources :transactions, controller: 'accounts/transactions',
                               only: [:index, :update, :destroy]
    end
    resource :transaction_category_set, controller: 'transaction_category_set',
                                        only: [:show, :update]
    resources :transactions, only: [:index]
    resources :synchronizers, only: [:index, :update, :destroy] do
      post :_perform_sync, to: 'synchronizers#perform_sync'
    end
    resources :account_identifiers, only: [:index, :update]
  end

  resources :synchronizer_types, only: [:index], defaults: { format: :json }

  namespace :webhook_endpoints, defaults: { format: :json } do
    namespace :syncer_receiving do
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
