require 'manageiq-messaging'

class EventService
  EVENT_REQUEST_STARTED  = 'request_started'.freeze
  EVENT_REQUEST_FINISHED = 'request_finished'.freeze
  EVENT_APPROVER_GROUP_NOTIFIED = 'approver_group_notified'.freeze
  EVENT_APPROVER_GROUP_FINISHED = 'approver_group_finished'.freeze
  EVENT_SENDER = 'approval_service'.freeze

  attr_accessor :request

  def initialize(request)
    self.request = request
  end

  def approver_group_notified(stage)
    send_event(EVENT_APPROVER_GROUP_NOTIFIED,
               :request_id => request.id,
               :group_name => group_name(stage))
  end

  def approver_group_finished(stage)
    send_event(EVENT_APPROVER_GROUP_FINISHED,
               :request_id => request.id,
               :group_name => group_name(stage),
               :decision   => stage.decision,
               :reason     => stage.reason)
  end

  def request_started
    send_event(EVENT_REQUEST_STARTED, :request_id => request.id)
  end

  def request_finished
    send_event(EVENT_REQUEST_FINISHED,
               :request_id => request.id,
               :decision   => request.decision,
               :reason     => request.reason || '')
  end

  private

  def group_name(stage)
    ContextService.new(request.context).as_org_admin do
      stage.name # need call to RBAC to get group/stage name
    end
  end

  def topic
    @topic ||= ENV['QUEUE_NAME'] || 'approval_events'.freeze
  end

  def send_event(event, payload)
    Rails.logger.info("Sending event " + event)
    ManageIQ::Messaging::Client.open(
      :protocol => 'Kafka',
      :host     => ENV['QUEUE_HOST'] || 'localhost',
      :port     => ENV['QUEUE_PORT'] || 9092,
      :encoding => 'json'
    ) do |client|
      client.publish_topic(:service => topic, :sender => EVENT_SENDER, :event => event, :payload => payload)
    end
  rescue StandardError, RBACApiClient::ApiError => error
    Rails.logger.error("Event sending failed. Reason: #{error.message}")
  end
end
