Rails.application.routes.draw do
  mount SwaggerUiEngine::Engine, :at => '/open-api'

  def add_swagger_route(http_method, path, opts = {})
    prefix = "api"
    if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
      prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
    end

    full_path = path.gsub(/{(.*?)}/, ':\1')
    scope :as => :api, :module => "api", :path => prefix do
      match "/v0/*path", :via => [:delete, :get, :options, :patch, :post], :to => redirect(:path => "/#{prefix}/v0.0/%{path}", :only_path => true)
      namespace :v0x0, :path => "v0.0" do
        match full_path, :to => "#{opts.fetch(:controller_name)}##{opts[:action_name]}", :via => http_method
      end
    end
  end

  add_swagger_route 'POST', '/groups', :controller_name => 'admins', :action_name => 'add_group'
  add_swagger_route 'POST', '/users', :controller_name => 'admins', :action_name => 'add_user'
  add_swagger_route 'POST', '/templates/{template_id}/workflows', :controller_name => 'admins', :action_name => 'add_workflow'
  add_swagger_route 'GET', '/users/{id}', :controller_name => 'admins', :action_name => 'fetch_user_by_id'
  add_swagger_route 'GET', '/users', :controller_name => 'admins', :action_name => 'fetch_users'
  add_swagger_route 'GET', '/groups/{group_id}/users', :controller_name => 'admins', :action_name => 'fetch_users_by_group_id'
  add_swagger_route 'GET', '/groups/{id}', :controller_name => 'admins', :action_name => 'fetch_group_by_id'
  add_swagger_route 'GET', '/groups', :controller_name => 'admins', :action_name => 'fetch_groups'
  add_swagger_route 'GET', '/users/{user_id}/groups', :controller_name => 'admins', :action_name => 'fetch_groups_by_user_id'
  add_swagger_route 'GET', '/requests', :controller_name => 'admins', :action_name => 'fetch_requests'
  add_swagger_route 'GET', '/users/{user_id}/requests', :controller_name => 'admins', :action_name => 'fetch_requests_by_user_id'
  add_swagger_route 'GET', '/stages/{id}', :controller_name => 'admins', :action_name => 'fetch_stage_by_id'
  add_swagger_route 'GET', '/templates/{id}', :controller_name => 'admins', :action_name => 'fetch_template_by_id'
  add_swagger_route 'GET', '/templates/{template_id}/workflows', :controller_name => 'admins', :action_name => 'fetch_template_workflows'
  add_swagger_route 'GET', '/templates', :controller_name => 'admins', :action_name => 'fetch_templates'
  add_swagger_route 'GET', '/workflows/{id}', :controller_name => 'admins', :action_name => 'fetch_workflow_by_id'
  add_swagger_route 'GET', '/workflows/{workflow_id}/requests', :controller_name => 'admins', :action_name => 'fetch_workflow_requests'
  add_swagger_route 'GET', '/workflows/{workflow_id}/groups', :controller_name => 'admins', :action_name => 'fetch_groups_by_workflow_id'
  add_swagger_route 'GET', '/workflows', :controller_name => 'admins', :action_name => 'fetch_workflows'
  add_swagger_route 'POST', '/groups/{id}', :controller_name => 'admins', :action_name => 'group_operation'
  add_swagger_route 'DELETE', '/users/{id}', :controller_name => 'admins', :action_name => 'remove_user'
  add_swagger_route 'DELETE', '/groups/{id}', :controller_name => 'admins', :action_name => 'remove_group'
  add_swagger_route 'DELETE', '/workflows/{id}', :controller_name => 'admins', :action_name => 'remove_workflow'
  add_swagger_route 'PATCH', '/users/{id}', :controller_name => 'admins', :action_name => 'update_user'
  add_swagger_route 'PATCH', '/groups/{id}', :controller_name => 'admins', :action_name => 'update_group'
  add_swagger_route 'PATCH', '/workflows/{id}', :controller_name => 'admins', :action_name => 'update_workflow'
  add_swagger_route 'POST', '/stages/{stage_id}/actions', :controller_name => 'users', :action_name => 'add_action'
  add_swagger_route 'GET', '/stages/{stage_id}/actions', :controller_name => 'users', :action_name => 'fetch_actions_by_stage_id'
  add_swagger_route 'GET', '/actions/{id}', :controller_name => 'users', :action_name => 'fetch_action_by_id'
  add_swagger_route 'GET', '/stages/{id}', :controller_name => 'users', :action_name => 'fetch_stage_by_id'
  add_swagger_route 'POST', '/workflows/{workflow_id}/requests', :controller_name => 'requesters', :action_name => 'add_request'
  add_swagger_route 'GET', '/requests/{id}', :controller_name => 'requesters', :action_name => 'fetch_request_by_id'
  add_swagger_route 'GET', '/requests/{request_id}/stages', :controller_name => 'requesters', :action_name => 'fetch_request_stages'
end
