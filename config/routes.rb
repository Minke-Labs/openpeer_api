Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      resources :lists, only: [:index, :create]
      resources :tokens, only: [:index]
      resources :currencies, only: [:index]
      resources :banks, only: [:index]
      resources :payment_methods, only: [:index]
    end

    get "/webhooks", to: "webhooks#index"
    post "/webhooks", to: "webhooks#create"
  end
end
