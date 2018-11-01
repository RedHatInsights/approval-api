class StageUpdateService
  attr_accessor :stage

  def initialize(stage_id)
    self.stage = Stage.find(stage_id)
  end

  def update(options)
    old_state = stage.state
    stage.update_attributes(options)
    return if old_state == stage.state
    if stage.state == Stage::NOTIFIED_STATE
      EventService.new(stage.request).approver_group_notified(stage)
    elsif stage.state == Stage::FINISHED_STATE
      EventService.new(stage.request).approver_group_finished(stage)
    end
  end
end
