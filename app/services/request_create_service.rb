class RequestCreateService
  attr_accessor :workflows

  def create(options)
    requester = Insights::API::Common::Request.current.user
    options = options.transform_keys(&:to_sym)
    create_options = options.slice(:name, :description).merge(
      :requester_name  => "#{requester.first_name} #{requester.last_name}",
      :request_context => RequestContext.new(:content => options[:content])
    )

    self.workflows = WorkflowFindService.new.find_by_tag_resources(options[:tag_resources]).to_a.delete_if { |wf| wf == Workflow.default_workflow }

    request =
      Request.transaction do
        Request.create!(create_options).tap do |req|
          create_child_requests(req) unless default_approve?
        end
      end

    prepare_request(request)
    request
  end

  private

  def create_child_requests(request)
    if workflows.size == 1 && workflows.first.group_refs.size == 1
      update_leaf_with_workflow(request, workflows.first.id, workflows.first.group_refs.first)
      return
    end

    workflows.each do |workflow|
      workflow.group_refs.each do |group_ref|
        child_request = request.create_child
        update_leaf_with_workflow(child_request, workflow.id, group_ref)
      end
    end
    update_root_group_name(request)
  end

  def update_leaf_with_workflow(leaf_request, workflow_id, group_ref)
    group_name = if group_ref
                   ContextService.new(leaf_request.context).as_org_admin do
                     Group.find(group_ref).name
                   end
                 end

    leaf_request.update!(:workflow_id => workflow_id, :group_ref => group_ref, :group_name => group_name)
  end

  def update_root_group_name(request)
    request.update!(:group_name => request.children.map(&:group_name).reverse.join(","))
  end

  def default_approve?
    workflows.blank?
  end

  def auto_approve?
    ENV['AUTO_APPROVAL'] && ENV['AUTO_APPROVAL'] != 'n'
  end

  def prepare_request(request)
    Thread.new do
      ContextService.new(request.context).with_context do
        if default_approve? || auto_approve?
          auto_approve(request)
        else
          start_request(request)
        end
      end
    end
  end

  def auto_approve(request)
    sleep_time = ENV['AUTO_APPROVAL_INTERVAL'].to_f

    start_request(request)

    sub_requests = request.parent? ? request.children : [request]

    sub_requests.reverse.each do |req|
      req.update!(:workflow => Workflow.default_workflow) unless req.workflow_id # each leaf must have a workflow
      group_auto_approve(req, sleep_time)
    end
  end

  def group_auto_approve(request, sleep_time)
    sleep(sleep_time)
    ActionCreateService.new(request.id).create(
      :operation    => Action::APPROVE_OPERATION,
      :processed_by => 'system',
      :comments     => 'System approved'
    )
  end

  def start_request(request)
    sub_request_ids(request).each do |rid|
      ActionCreateService.new(rid).create(
        :operation    => Action::START_OPERATION,
        :processed_by => 'system'
      )
    end
  end

  def sub_request_ids(request)
    return [request.id] if request.leaf?

    last = request.children.last
    Request.where(:parent_id => last.parent_id, :workflow_id => last.workflow_id).pluck(:id)
  end
end
