class ActionCreateService
  attr_accessor :stage

  def initialize(stage_id)
    self.stage = Stage.find(stage_id)
  end

  def create(options)
    stage_options = validate_operation(options)

    options = options.transform_keys(&:to_sym)
    unless options[:processed_by]
      requester = ManageIQ::API::Common::Request.current.user
      options[:processed_by] = requester.username
    end

    Action.create!(options.merge(:stage => stage)).tap do
      if stage_options
        StageUpdateService.new(stage.id).update(stage_options)
        stage.reload
      end
    end
  end

  private

  def validate_operation(options)
    options = HashWithIndifferentAccess.new(options)
    operation = options['operation']
    raise Exceptions::ApprovalError, "Invalid operation: #{operation}" unless Action::OPERATIONS.include?(operation)

    send(operation, options['comments'])
  end

  def memo(_comments)
    nil
  end

  def notify(_comments)
    unless stage.state == Stage::PENDING_STATE
      raise Exceptions::InvalidStateTransitionError, "Current stage is not in pending state"
    end

    {:state => Stage::NOTIFIED_STATE}
  end

  def skip(_comments)
    unless stage.state == Stage::PENDING_STATE
      raise Exceptions::InvalidStateTransitionError, "Current stage is not in pending state"
    end

    {:state => Stage::SKIPPED_STATE}
  end

  def approve(comments)
    unless stage.state == Stage::NOTIFIED_STATE
      raise Exceptions::InvalidStateTransitionError, "Current stage is not in notified state"
    end

    {:state => Stage::FINISHED_STATE, :decision => Stage::APPROVED_STATUS}.tap do |h|
      h[:reason] = comments if comments
    end
  end

  def deny(comments)
    unless stage.state == Stage::NOTIFIED_STATE
      raise Exceptions::InvalidStateTransitionError, "Current stage is not in notified state"
    end
    raise Exceptions::ApprovalError, "Reason to deny the request is missing" unless comments

    {:state => Stage::FINISHED_STATE, :decision => Stage::DENIED_STATUS, :reason => comments}
  end
end
