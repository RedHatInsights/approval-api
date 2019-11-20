require 'rbac-api-client'
module RBAC
  class Sync
    def initialize(user_file)
      @request = create_request(user_file)
    end

    def sync_workflows
      Insights::API::Common::Request.with_request(@request) do
        aps = AccessProcessService.new
        Workflow.all.each do |workflow|
          aps.add_resource_to_groups(workflow.id, workflow.group_refs)
        end
      end
    end

    private

    def create_request(user_file)
      raise "File #{user_file} not found" unless File.exist?(user_file)

      user = YAML.load_file(user_file)
      {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
    end
  end
end
