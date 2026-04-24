Rails.application.routes.draw do
  # Invite-only: no public registrations.
  # Note: :passwords routes are kept (Devise references new_user_password_path
  # internally on failed sign-in flash), but no link is exposed in the UI.
  # Real password resets happen via `bin/rails admin:reset_password`.
  devise_for :users, skip: [:registrations]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: redirect('/start')
  
  get 'welcome' => 'pages#home'

  get 'start' => 'graduates#start'
  get 'list' => 'graduates#list'

  get 'print' => 'graduates#to_print'
  patch 'print' => 'graduates#print', as: 'print_graduate'
  get 'get_print' => 'graduates#get_print_html'

  # Graduates collection-specific route
  patch 'bulk_print' => 'graduates#bulk_print', as: 'bulk_print'
  get 'show_bulk', to: 'graduates#show_bulk', as: 'show_bulk'


  resources :graduates, except: :index, param: :buid do
    member do
      patch :checkin
      get :checkin
    end
    collection do
      get :stats
    end
  end

  get '/graduates', to: redirect('/start')
end
