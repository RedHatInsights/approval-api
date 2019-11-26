require 'rbac-api-client'

namespace :approval do
  desc "create RBAC roles for existing workflows with an given user yaml file"
  task :sync_rbac_roles => :environment do
    raise "Please provide a user yaml file" unless ENV['USER_FILE']

    req = create_request(ENV['USER_FILE'])
    sync_workflows(req)
  end

  def sync_workflows(request)
    Insights::API::Common::Request.with_request(request) do
      aps = AccessProcessService.new
      Workflow.all.each do |workflow|
        aps.add_resource_to_groups(workflow.id, workflow.group_refs)
      end
    end
  end

  def create_request(user_file)
    raise "File #{user_file} not found" unless File.exist?(user_file)

    user = YAML.load_file(user_file)
    {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
  end
end
