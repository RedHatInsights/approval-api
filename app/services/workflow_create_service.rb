require_relative 'mixins/group_validate_mixin'

class WorkflowCreateService
  include GroupValidateMixin
  attr_accessor :template

  def initialize(template_id)
    self.template = Template.find(template_id)
  end

  def create(options)
    options[:group_refs] = validate_approver_groups(options[:group_refs]) if options[:group_refs]

    template.workflows.create!(options)
  end
end
