class RequestUpdateService
  attr_accessor :request

  def initialize(request_id)
    self.request = Request.find(request_id)
  end

  def update(options)
    old_state = request.state
    request.update_attributes(options)
    return if old_state == request.state
    if request.state == Request::NOTIFIED_STATE
      EventService.new(request).request_started
    elsif request.state == Request::FINISHED_STATE
      EventService.new(request).request_finished
    end
  end
end
