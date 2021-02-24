class ActionCreateService
  attr_accessor :request

  def initialize(request_id)
    self.request = Request.find(request_id)
  end

  def create(options)
    request_options = validate_operation(options)

    options = options.transform_keys(&:to_sym)
    unless options[:processed_by]
      requester = Insights::API::Common::Request.current.user
      options[:processed_by] = requester.username
    end

    Action.create!(options.merge(:request => request)).tap do
      if request_options
        RequestUpdateService.new(request.id).update(request_options)
        request.reload
      end
    end
  end

  private

  def validate_operation(options)
    options = HashWithIndifferentAccess.new(options)
    operation = options['operation']
    raise Exceptions::UserError, "Invalid operation: #{operation}" unless Action::OPERATIONS.include?(operation)

    send(operation, options['comments'])
  end

  def memo(comments)
    raise Exceptions::UserError, "The memo message cannot be blank" if comments.blank?
  end

  def start(_comments)
    unless request.state == Request::PENDING_STATE
      raise Exceptions::InvalidStateTransitionError, "Current request is not pending state"
    end

    {:state => Request::STARTED_STATE}
  end

  def notify(_comments)
    unless request.state == Request::STARTED_STATE
      raise Exceptions::InvalidStateTransitionError, "Current request is not started state"
    end

    {:state => Request::NOTIFIED_STATE}
  end

  def skip(_comments)
    unless request.state == Request::PENDING_STATE
      raise Exceptions::InvalidStateTransitionError, "Current request is not in pending state"
    end

    {:state => Request::SKIPPED_STATE}
  end

  def approve(comments)
    unless request.state == Request::NOTIFIED_STATE
      raise Exceptions::InvalidStateTransitionError, "Current request is not in notified state"
    end
    raise Exceptions::InvalidStateTransitionError, "Only child level request can be approved" if request.parent?

    {:state => Request::COMPLETED_STATE, :decision => Request::APPROVED_STATUS}.tap do |h|
      h[:reason] = comments if comments
    end
  end

  def deny(comments)
    unless request.state == Request::NOTIFIED_STATE
      raise Exceptions::InvalidStateTransitionError, "Current request is not in notified state"
    end
    raise Exceptions::UserError, "A reason has to be provided if a request is being denied" if comments.blank?
    raise Exceptions::InvalidStateTransitionError, "Only child level request can be denied" if request.parent?

    {:state => Request::COMPLETED_STATE, :decision => Request::DENIED_STATUS, :reason => comments}
  end

  def cancel(comments)
    raise Exceptions::InvalidStateTransitionError, "Only root level request can be canceled" unless request.root?
    raise Exceptions::InvalidStateTransitionError, "The request has already finished" if request.finished?

    {:state => Request::CANCELED_STATE, :decision => Request::CANCELED_STATUS}.tap do |h|
      h[:reason] = comments if comments
    end
  end

  def error(comments)
    raise Exceptions::InvalidStateTransitionError, "Current request has already finished" if request.finished?
    raise Exceptions::UserError, "Failure reason is missing" unless comments
    raise Exceptions::InvalidStateTransitionError, "Only child level request can be flagged error" if request.parent?

    {:state => Request::FAILED_STATE, :decision => Request::ERROR_STATUS, :reason => comments}
  end
end
