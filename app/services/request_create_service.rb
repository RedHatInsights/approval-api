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
        :decision => Stage::UNKNOWN_STATUS,
      )
    end

    create_options = options.merge(
      :workflow => workflow,
      :state    => Request::PENDING_STATE,
      :decision => Request::UNKNOWN_STATUS,
      :stages   => stages
    )
    Request.create!(create_options).tap do |request|
      start_approval_process(request) if ENV['AUTO_APPROVAL'] && ENV['AUTO_APPROVAL'] != 'n'
    end
  end

  private

  def start_approval_process(request)
    Thread.new do
      auto_approve(request)
    end
  end

  def auto_approve(request)
    sleep_time = ENV['AUTO_APPROVAL_INTERVAL'].to_f
    sleep(sleep_time)
    RequestUpdateService.new(request.id).update(:state => Request::NOTIFIED_STATE)

    request.stages.each { |stage| group_auto_approve(stage, sleep_time) }

    RequestUpdateService.new(request.id).update(
      :state    => Request::FINISHED_STATE,
      :decision => Request::APPROVED_STATUS,
      :reason   => 'ok'
    )
  end

  def group_auto_approve(stage, sleep_time)
    sleep(sleep_time)
    StageUpdateService.new(stage.id).update(:state => Stage::NOTIFIED_STATE)
    stage.actions << Action.new(
      :notified_at  => Time.now,
      :processed_by => stage.group.contact_setting
    )

    sleep(sleep_time)
    stage.actions.first.update_attributes(
      :actioned_at => Time.now,
      :decision    => Action::APPROVED_STATUS,
      :comments    => 'ok'
    )

    StageUpdateService.new(stage.id).update(
      :state    => Stage::FINISHED_STATE,
      :decision => Stage::APPROVED_STATUS,
      :comments => 'ok'
    )
  end
end
