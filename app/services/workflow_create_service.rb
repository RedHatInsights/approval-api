class WorkflowCreateService
  attr_accessor :template

  def initialize(template_id)
    self.template = Template.find(template_id)
  end

  def create(options)
    template.workflows.create!(options).tap do |workflow|
      begin
        if options[:group_refs]
          ContextService.new(ManageIQ::API::Common::Request.current.to_h.transform_keys(&:to_s)).as_org_admin do
            AccessProcessService.new.add_resource_to_groups(workflow.id, options[:group_refs])
          end
        end
      rescue Exceptions::RBACError => error
        Rails.logger.error("Exception when creating workflow: #{error}")
        workflow&.destroy!
        raise error
      end
    end
  end
end
