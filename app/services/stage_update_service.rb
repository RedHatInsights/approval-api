class StageUpdateService
  attr_accessor :stage

  def initialize(stage_id)
    self.stage = Stage.find(stage_id)
  end

  def update(options)
    old_state = stage.state
    stage.update_attributes(options)
    return if old_state == stage.state
    case stage.state
    when Stage::NOTIFIED_STATE
      request_started if first_stage?
      EventService.new(stage.request).approver_group_notified(stage)
    when Stage::FINISHED_STATE
      EventService.new(stage.request).approver_group_finished(stage)
      stage_finished(stage.decision) unless external_processing?
      request_finished(stage.decision, stage.reason) if last_stage?
    when Stage::SKIPPED_STATE
      last_stage_skipped if last_stage?
    end
  end

  private

  def first_stage?
    stage.id == stage.request.stages.first.id
  end

  def last_stage?
    stage.id == stage.request.stages.last.id
  end

  def external_processing?
    stage.request.workflow.external_processing?
  end

  def last_stage_skipped
    last_decision = nil
    last_reason   = nil
    stage.request.stages.each do |st|
      next if st.state == Stage::SKIPPED_STATE
      last_decision = st.decision
      last_reason   = st.reason
    end
    request_finished(last_decision, last_reason)
  end

  def request_started
    RequestUpdateService.new(stage.request.id).update(
      :state    => Request::NOTIFIED_STATE
    )
  end

  def request_finished(last_decision, last_reason)
    RequestUpdateService.new(stage.request.id).update(
      :state    => Request::FINISHED_STATE,
      :decision => last_decision,
      :reason   => last_reason
    )
  end

  def stage_finished(decision)
    next_stage = stage.request.stages.find { |s| s.state == Stage::PENDING_STATE }
    return unless next_stage

    operation = decision == Stage::DENIED_STATUS ? Action::SKIP_OPERATION : Action::NOTIFY_OPERATION
    ActionCreateService.new(next_stage.id).create(:operation => operation, :processed_by => 'system')
  end
end
