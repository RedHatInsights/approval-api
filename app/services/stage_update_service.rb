class StageUpdateService
  attr_accessor :stage

  def initialize(stage_id)
    self.stage = Stage.find(stage_id)
  end

  def update(options)
    options = options.transform_keys(&:to_sym)

    old_state = stage.state
    stage.update_attributes(options)
    return if old_state == stage.state
    case stage.state
    when Stage::NOTIFIED_STATE
      EventService.new(stage.request).approver_group_notified(stage)
    when Stage::FINISHED_STATE
      EventService.new(stage.request).approver_group_finished(stage)
      stage_finished(stage.decision)
      request_finished(stage.decision, stage.reason) if last_stage?
    when Stage::SKIPPED_STATE
      last_stage_skipped if last_stage?
    when Stage::CANCELED_STATE
      stage_finished('canceled')
      request_canceled(stage.reason) if last_stage?
    end
  end

  private

  def last_stage?
    stage.id == stage.request.stages.last.id
  end

  def external_processing?
    stage.request.workflow.external_processing?
  end

  def external_signal?
    stage.request.workflow.external_signal?
  end

  def last_stage_skipped
    stage.request.stages.reverse_each do |st|
      next if st.state == Stage::SKIPPED_STATE
      if st.state == Stage::CANCELED_STATE
        request_canceled(st.reason)
      else
        request_finished(st.decision, st.reason)
      end
      break
    end
  end

  def request_finished(last_decision, last_reason)
    RequestUpdateService.new(stage.request.id).update(
      :state    => Request::FINISHED_STATE,
      :decision => last_decision,
      :reason   => last_reason
    )
  end

  def request_canceled(reason)
    RequestUpdateService.new(stage.request.id).update(
      :state  => Request::CANCELED_STATE,
      :reason => reason
    )
  end

  def stage_finished(decision)
    stage.update_attributes(:random_access_key => nil)
    if external_signal?
      signal_external_approval_process(decision)
    else
      auto_next_stage(decision)
    end
  end

  def auto_next_stage(decision)
    next_stage = stage.request.stages.find { |s| s.state == Stage::PENDING_STATE }
    return unless next_stage

    operation = [Stage::DENIED_STATUS, 'canceled'].include?(decision) ? Action::SKIP_OPERATION : Action::NOTIFY_OPERATION
    ActionCreateService.new(next_stage.id).create(:operation => operation, :processed_by => 'system')
  end

  def signal_external_approval_process(decision)
    template = stage.request.workflow.template
    processor_class = "#{template.signal_setting['processor_type']}_process_service".classify.constantize
    processor_class.new(stage.request).signal(decision)
  end
end
