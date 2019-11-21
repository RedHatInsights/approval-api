class RequestUpdateService
  attr_accessor :request

  def initialize(request_id)
    self.request = Request.find(request_id)
  end

  def update(options)
    return if options[:state] == request.state

    send(options[:state], options)
  end

  private

  def started(options)
    start_request if request.leaf?

    request.update!(options)

    EventService.new(request).request_started if request.root?

    update_parent(options) if request.child?

    notify_request if request.leaf?
  end

  def notified(options)
    request.update!(options.merge(:notified_at => DateTime.now))

    EventService.new(request).approver_group_notified if request.leaf?

    update_parent(options) if request.child?
  end

  def completed(options)
    finish_request(options[:decision]) if request.leaf?

    return if request.state == Request::CANCELED_STATE

    EventService.new(request).approver_group_finished if request.leaf?

    return child_completed(options) if request.child?

    return parent_completed(options) if request_completed?(request, options[:decision])
  end

  # Root only.
  def canceled(options)
    skip_leaves
    request.update!(options.merge(:finished_at => DateTime.now))

    EventService.new(request).request_canceled
  end

  # Leaf only. skipped is caused by cancel or deny. This state will not propagate to root
  def skipped(options)
    request.update!(options.merge(:finished_at => DateTime.now))
    request.parent.invalidate_number_of_finished_children
  end

  def skip_leaves
    leaves.each do |leaf|
      next unless leaf.state == Request::PENDING_STATE

      ActionCreateService.new(leaf.id).create(:operation => Action::SKIP_OPERATION, :processed_by => 'system')
    end
  end

  def child_completed(options)
    request.update!(options.merge(:finished_at => DateTime.now))
    request.parent.invalidate_number_of_finished_children
    update_parent(options)
    if options[:decision] == Request::DENIED_STATUS
      skip_leaves
    else
      start_next_leaves if peers_approved?(request)
    end
  end

  def parent_completed(options)
    request.update!(options.merge(:finished_at => DateTime.now))
    EventService.new(request).request_completed
  end

  def request_completed?(decision)
    request.number_of_finished_children == request.number_of_children || decision == Request::DENIED_STATUS
  end

  def peers_approved?(request)
    peers = Request.where(:workflow_id => request.workflow_id, :parent_id => request.parent_id)

    peers.any? { |peer| peer.decision != Request::APPROVED_STATUS } ? false : true
  end

  def start_next_leaves
    pending_leaves = next_pending_leaves
    return unless pending_leaves

    pending_leaves.each do |leaf|
      ActionCreateService.new(leaf.id).create(:operation => Action::START_OPERATION, :processed_by => 'system')
    end
  end

  def leaves
    request.root.children.reverse # sort from oldest to latest
  end

  def next_pending_leaves
    leaves.each_with_object([]) do |leaf, peers|
      next unless leaf.state == Request::PENDING_STATE

      peers << leaf if peers.empty? || leaf.workflow_id == peers.first.workflow_id
    end
  end

  def update_parent(options)
    RequestUpdateService.new(request.parent_id).update(options)
  end

  # start the external approval process if configured
  def start_request
    return unless bypass || request.workflow.try(:external_processing?)

    template = request.workflow.template
    processor_class = "#{template.process_setting['processor_type']}_process_service".classify.constantize
    ref = processor_class.new(request).start
    request.update!(:process_ref => ref)
  end

  def notify_request
    return if request.workflow.try(:external_processing?)

    ActionCreateService.new(request.id).create(:operation => Action::NOTIFY_OPERATION, :processed_by => 'system')
  end

  # complete the external approval process if configured
  def finish_request(decision)
    return unless bypass || request.workflow.try(:external_processing?)

    template = request.workflow.template
    processor_class = "#{template.signal_setting['processor_type']}_process_service".classify.constantize
    processor_class.new(request).signal(decision)
  end

  # TODO: remove this method once BPM changes are ready
  def bypass
    true
  end
end
