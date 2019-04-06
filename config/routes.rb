require 'resque/server'
Rails.application.routes.draw do


  get 'accounts/setup'
  get 'products/show'
  post 'products/search'

  root to: 'products#show'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end

  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
