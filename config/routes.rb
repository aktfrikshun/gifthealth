# frozen_string_literal: true

Rails.application.routes.draw do
  root 'prescriptions#index'
  
  # Documentation viewer
  get 'documents/:name', to: 'documents#show', as: :document
  
  resources :patients, only: [:index, :destroy] do
    member do
      delete :clear_prescriptions
    end
    collection do
      delete :reset_all
    end
  end
  
  resources :prescriptions do
    collection do
      post :upload
      post :process_events
    end
    member do
      patch :increment_fill
      patch :decrement_fill
    end
  end
  
  namespace :api do
    namespace :v1 do
      resources :prescription_events, only: [:create] do
        collection do
          post :batch
        end
      end
    end
  end
end
