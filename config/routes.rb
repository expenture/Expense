Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users, only: [:sessions, :confirmations, :unlocks]

  resources :users, defaults: { format: :json }

  namespace :me, defaults: { format: :json } do
    resources :accounts, only: [:index, :update, :destroy] do
      resources :transactions, controller: 'accounts/transactions',
                               only: [:index, :update, :destroy]
    end

    resource :transaction_category_set, controller: 'transaction_category_set',
                                        only: [:show, :update]

    resources :transactions, only: [:index]
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
