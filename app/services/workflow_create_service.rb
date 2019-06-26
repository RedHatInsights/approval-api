class WorkflowCreateService
  attr_accessor :template

  def initialize(template_id)
    self.template = Template.find(template_id)
  end

  def create(options)
    template.workflows.create!(options).tap do |workflow|
      begin
        AccessProcessService.new.add_resource_to_groups(workflow.id, options[:group_refs]) if options[:group_refs]
      rescue Exceptions::RBACError => error
        Rails.logger.error("Exception when creating workflow: #{error}")
        workflow.destroy! if workflow
        raise error
      end
    end
  end
end
