Rails.application.routes.draw do
  scope path: Rails.configuration.pompa.url do
    if Rails.configuration.pompa.endpoints.admin
      resources :events
      resources :victims, only: [:index, :show, :destroy]
      resources :scenarios
      resources :campaigns
      resources :attachments
      resources :resources
      resources :templates
      resources :goals
      resources :mailers
      resources :groups
      resources :targets
      resources :workers, only: [:index, :show]

      match '/targets/upload', via: [:post, :put], to: 'targets#upload'

      post '/groups/:id/clear', to: 'groups#clear'

      get '/scenarios/:id/report', to: 'scenario_reports#show'

      get '/scenarios/:id/victims-summary', to: 'scenarios#victims_summary'
      post '/scenarios/:id/synchronize-group', to: 'scenarios#synchronize_group'

      get '/victims/:id/report', to: 'victim_reports#show'

      post '/victims/:id/send-email', to: 'victims#send_email'
      post '/victims/:id/reset-state', to: 'victims#reset_state'

      post '/campaigns/:id/start', to: 'campaigns#start'
      post '/campaigns/:id/pause', to: 'campaigns#pause'
      post '/campaigns/:id/finish', to: 'campaigns#finish'
      post '/campaigns/:id/synchronize-events', to: 'campaigns#synchronize_events'

      get '/resources/:id/download', to: 'resources#download'
      match '/resources/:id/upload', via: [:post, :put], to: 'resources#upload'

      get '/events/series/:period', to: 'events#series'
    end

    if Rails.configuration.pompa.endpoints.public
      scope path: '/public' do
        match '/', via: :all, to: 'public#index'
        match '/report', via: :all, to: 'public#report'
        match '/render', via: [:get], to: 'public#_render'
        match '*path', via: :all, to: 'public#not_found'
      end
    end


    if Rails.configuration.pompa.endpoints.sidekiq_console
      require 'sidekiq/web'
      Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
      mount Sidekiq::Web => '/sidekiq'
    end
  end
end
