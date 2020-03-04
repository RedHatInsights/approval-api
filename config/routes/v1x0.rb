namespace :v1x0, :path => "v1.0" do
  resources :stageaction, :only => %i(show update)

  get "/openapi.json", :to => "root#openapi"
  post "/graphql", :to => "graphql#query"

  resources :actions, :only => [:show]

  resources :requests, :only => %i(create index show) do
    resources :requests, :only => [:index]
    resources :actions, :only => %i(create index)
  end

  get "/requests/:id/content", :to => "requests#show"

  resources :workflows, :only => %i(index destroy update show)

  post '/workflows/:id/link', :to => "workflows#link", :as => 'link'
  post '/workflows/:id/unlink', :to => "workflows#unlink", :as => 'unlink'

  resources :templates, :only => %i(index show) do
    resources :workflows, :only => %i(create index)
  end
end
