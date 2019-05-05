require 'resque/server'
Rails.application.routes.draw do

  get 'prices/edit'
  post 'prices/edit'
  get 'prices/template'

  get 'lists/put'
  get 'lists/show'
  post 'lists/show'
  get 'lists/check'
  post 'lists/check'
  get 'lists/regist'

  get 'accounts/setup'
  post 'accounts/regist'

  get 'products/check'
  get 'products/show'
  get 'products/search'
  post 'products/search'
  get 'products/setup'
  post 'products/setup'
  get 'products/listup'
  post 'products/listup'
  post 'products/import'
  post 'products/update'
  post 'products/filter'
  get 'products/explain'

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
