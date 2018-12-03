class ActionCreateService
  attr_accessor :stage

  def initialize(stage_id)
    self.stage = Stage.find(stage_id)
  end

  def create(options)
    Action.create!(options.merge(:stage => stage)).tap do |action|
      case action.operation
      when Action::NOTIFY_OPERATION
        StageUpdateService.new(stage.id).update(:state => Stage::NOTIFIED_STATE)
      when Action::SKIP_OPERATION
        StageUpdateService.new(stage.id).update(:state => Stage::SKIPPED_STATE)
      when Action::APPROVE_OPERATION
        StageUpdateService.new(stage.id).update(
          :state    => Stage::FINISHED_STATE,
          :decision => Stage::APPROVED_STATUS,
          :reason   => action.comments
        )
      when Action::DENY_OPERATION
        StageUpdateService.new(stage.id).update(
          :state    => Stage::FINISHED_STATE,
          :decision => Stage::DENIED_STATUS,
          :reason   => action.comments
        )
      end
    end
  end
end
