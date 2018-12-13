class RequestCreateService
  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def create(options)
    stages = workflow.groups.collect do |group|
      Stage.new(
        :group    => group,
        :state    => Stage::PENDING_STATE,
        :decision => Stage::UNDECIDED_STATUS,
      )
    end

    create_options = options.merge(
      :workflow => workflow,
      :state    => Request::PENDING_STATE,
      :decision => Request::UNDECIDED_STATUS,
      :stages   => stages
    )
    Request.create!(create_options).tap do |request|
      start_approval_process(request) if default_approve? || auto_approve?
    end
  end

  private

  def default_approve?
    workflow.id == Workflow.default_workflow.try(:id)
  end

  def auto_approve?
    ENV['AUTO_APPROVAL'] && ENV['AUTO_APPROVAL'] != 'n'
  end

  def start_approval_process(request)
    Thread.new do
      default_approve? ? default_approve(request) : auto_approve(request)
    end
  end

  def auto_approve(request)
    sleep_time = ENV['AUTO_APPROVAL_INTERVAL'].to_f

    request.stages.each { |stage| group_auto_approve(stage, sleep_time) }
  end

  def group_auto_approve(stage, sleep_time)
    acs = ActionCreateService.new(stage.id)
    sleep(sleep_time)
    acs.create(
      :operation    => Action::NOTIFY_OPERATION,
      :processed_by => 'system',
      :comments     => "email sent to #{stage.group.contact_setting}"
    )

    sleep(sleep_time)
    acs.create(
      :operation    => Action::APPROVE_OPERATION,
      :processed_by => stage.group.contact_setting,
      :comments     => 'ok'
    )
  end

  def default_approve(request)
    request_started(request)
    request_finished(request)
  end

  def request_started(request)
    RequestUpdateService.new(request.id).update(
      :state    => Request::NOTIFIED_STATE
    )
  end

  def request_finished(request)
    RequestUpdateService.new(request.id).update(
      :state    => Request::FINISHED_STATE,
      :decision => Request::APPROVED_STATUS,
      :reason   => 'System approved'
    )
  end
end
