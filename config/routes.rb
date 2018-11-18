Rails.application.routes.draw do
  resources :posts
  root to: 'homepage#index'
  devise_for :users
end
