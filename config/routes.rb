Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get 'welcome' => 'pages#home'

  get 'start' => 'graduates#start'
  get 'list' => 'graduates#list'

  get 'print' => 'graduates#to_print'

  resources :graduates, param: :buid do
    member do
      get :show
      post :update

      patch :checkin
      get :checkin

      patch :print
      get :print

    end
  end

  # get 'graduates/confirm' => 'graduates#confirm', as: :grad_confirm
end
