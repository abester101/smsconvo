require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'

Rails.application.routes.draw do

  mount Resque::Server.new, :at => "/resque"

  root 'users#new'
  
  get '/hardbound.vcf', to: 'home#hardboundvcf', as: 'hardboundvcf'

  resources :users do 
    resources :messages
  end
  post '/messages/inbound', to: 'messages#inbound'
  resources :messages, only: :new
  post '/messages/send_to_all', to: 'messages#send_to_all'
  post '/messages/send_to_patrons', to: 'messages#send_to_patrons'

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create]
      put '/users/welcome', to: 'users#welcome'
      put '/users/update_patron', to: 'users#update_patron'
    end
  end
end
