Rails.application.routes.draw do
  # Authentication (Rails 8 generator) + self sign-up + profile.
  resource  :session, only: %i[new create destroy]
  resource  :registration, only: %i[new create]
  resources :passwords, param: :token
  resource  :profile, only: %i[show edit update]
  resource  :password_change, only: :update
  resource  :avatar, only: :show

  # Reusable confirm-before-delete dialog rendered into the remote_modal frame.
  resource  :confirmation, only: :show

  root "dashboard#index"

  resources :embeddings, only: %i[index show new create destroy] do
    collection do
      post :save_to_gallery
      post :bulk_destroy
      delete :all, action: :destroy_all
    end
  end
  resources :decodings, only: %i[index show new create destroy] do
    collection do
      post :bulk_destroy
      delete :all, action: :destroy_all
    end
  end
  resources :analyses, only: %i[index show new create destroy] do
    collection do
      post :bulk_destroy # by image_ids (group cards) or analysis_ids (rows)
      delete :all, action: :destroy_all
    end
  end
  resources :images, only: %i[index show new create update destroy] do
    member do
      get :convert
      get :analyses # all steganalyses of one image + run-more form
    end
    collection do
      post :bulk_destroy
      post :bulk_update_model
      delete :all, action: :destroy_all
    end
  end

  # Result callbacks from veil-core (token-authenticated, no CSRF, no login).
  post "callbacks/steganography" => "core_callbacks/steganography#create"
  post "callbacks/steganalysis"  => "core_callbacks/steganalysis#create"

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
