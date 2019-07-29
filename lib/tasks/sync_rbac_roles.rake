require 'rbac-api-client'

namespace :approval do
  desc "create RBAC roles for existing workflows with an given user yaml file"
  task :sync_rbac_roles => :environment do
    raise "Please provide a user yaml file" unless ENV['USER_FILE']

    obj = RBAC::Sync.new(ENV['USER_FILE'])
    obj.sync_workflows
  end
end
