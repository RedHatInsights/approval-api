Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args)
  end

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  scope :as => :api, :module => "api", :path => prefix do
    match "/v0/*path", :via => %i(delete get patch post), :to => redirect(:path => "/#{prefix}/v0.0/%{path}", :only_path => true)
    namespace :v0x1, :path => "v0.1" do
      resources :actions, :only => [:show]

      resources :stages, :only => [:show] do
        resources :actions, :only => %i(create index)
      end

      resources :requests, :only => %i(index show) do
        resources :stages, :only => [:index]
      end

      resources :workflows, :only => %i(index destroy update show) do
        resources :requests, :only => %i(create index)
      end

      resources :templates, :only => %i(index show) do
        resources :workflows, :only => %i(create index)
      end
    end
  end

  # Version 0.0
  def create_route(http_method, path, opts = {})
    prefix = "api"
    if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
      prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
    end

    full_path = path.gsub(/{(.*?)}/, ':\1')
    scope :as => :api, :module => "api", :path => prefix do
      namespace :v0x0, :path => "v0.0" do
        match full_path, :to => "#{opts.fetch(:controller_name)}##{opts[:action_name]}", :via => http_method
      end
    end
  end

  create_route 'POST', '/templates/{template_id}/workflows', :controller_name => 'admins', :action_name => 'add_workflow'
  create_route 'GET', '/requests', :controller_name => 'admins', :action_name => 'fetch_requests'
  create_route 'GET', '/stages/{id}', :controller_name => 'admins', :action_name => 'fetch_stage_by_id'
  create_route 'GET', '/templates/{id}', :controller_name => 'admins', :action_name => 'fetch_template_by_id'
  create_route 'GET', '/templates/{template_id}/workflows', :controller_name => 'admins', :action_name => 'fetch_template_workflows'
  create_route 'GET', '/templates', :controller_name => 'admins', :action_name => 'fetch_templates'
  create_route 'GET', '/workflows/{id}', :controller_name => 'admins', :action_name => 'fetch_workflow_by_id'
  create_route 'GET', '/workflows/{workflow_id}/requests', :controller_name => 'admins', :action_name => 'fetch_workflow_requests'
  create_route 'GET', '/workflows', :controller_name => 'admins', :action_name => 'fetch_workflows'
  create_route 'DELETE', '/workflows/{id}', :controller_name => 'admins', :action_name => 'remove_workflow'
  create_route 'PATCH', '/workflows/{id}', :controller_name => 'admins', :action_name => 'update_workflow'
  create_route 'POST', '/stages/{stage_id}/actions', :controller_name => 'users', :action_name => 'add_action'
  create_route 'GET', '/stages/{stage_id}/actions', :controller_name => 'users', :action_name => 'fetch_actions_by_stage_id'
  create_route 'GET', '/actions/{id}', :controller_name => 'users', :action_name => 'fetch_action_by_id'
  create_route 'GET', '/stages/{id}', :controller_name => 'users', :action_name => 'fetch_stage_by_id'
  create_route 'POST', '/workflows/{workflow_id}/requests', :controller_name => 'requesters', :action_name => 'add_request'
  create_route 'GET', '/requests/{id}', :controller_name => 'requesters', :action_name => 'fetch_request_by_id'
  create_route 'GET', '/requests/{request_id}/stages', :controller_name => 'requesters', :action_name => 'fetch_request_stages'
end
