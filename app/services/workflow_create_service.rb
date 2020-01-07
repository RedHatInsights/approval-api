class WorkflowCreateService
  attr_accessor :template

  def initialize(template_id)
    self.template = Template.find(template_id)
  end

  def create(options)
    if options[:group_refs]
      options[:access_control_entries] =
        options[:group_refs].collect do |uuid|
          AccessControlEntry.new(:group_uuid => uuid, :permission => 'approve')
        end
    end

    template.workflows.create!(options)
  end
end
