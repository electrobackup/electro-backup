Rails.application.routes.draw do
  namespace :admin do
    resources :orders
    resources :products do
      resources :stocks
    end
      resources :categories
  end
  devise_for :admins
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  authenticated :admin_user do
    root to: "admin#index", as: :admin_root
  end

  resources :categories, only: [:show]
  resources :products, only: [:show]

  get "admin" => "admin#index"
  get "cart" => "carts#show"
  post "checkout" => "checkouts#create"
  get "success" => "checkouts#success"
  get "cancel" => "checkouts#cancel"
  post "webhooks" => "webhooks#stripe"
  post '/checkout', to: 'checkouts#create'


#   post "/checkout", to: "checkouts#create"
# get "/checkout/shipping_form", to: "checkouts#shipping_form"
# post "/checkout/shipping_submit", to: "checkouts#submit_shipping"
# resources :checkouts, only: [:create] do
#   collection do
#     get :shipping_form
#     post :submit_shipping
#   end
# end
#
#  resource :checkouts, only: [:create] do
#     get :shipping_form, on: :collection
#     post :submit_shipping, on: :collection
#   end

  # Success and cancel routes
  get 'success', to: 'checkouts#success'
  get 'cancel', to: 'checkouts#cancel'
end
