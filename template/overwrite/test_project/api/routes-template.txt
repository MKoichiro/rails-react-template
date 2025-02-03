Rails.application.routes.draw do
  # Health check
  get '/health', to: ->(_) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }

  # api
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show]
    end
  end
end
