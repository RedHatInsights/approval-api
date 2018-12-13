class WorkflowCreateService
  attr_accessor :template

  def initialize(template_id)
    self.template = Template.find(template_id)
  end

  def create(options)
    template.workflows.create!(options)
  end
end
