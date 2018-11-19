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
      :group_name => stage.group.name
    )
  end

  def approver_group_finished(stage)
    send_event(EVENT_APPROVER_GROUP_FINISHED,
      :request_id => request.id,
      :group_name => stage.group.name,
      :decision   => stage.decision,
      :comments   => stage.comments
    )
  end

  def request_started
    send_event(EVENT_REQUEST_STARTED, :request_id => request.id)
  end

  def request_finished
    send_event(EVENT_REQUEST_FINISHED,
      :request_id => request.id,
      :decision   => request.decision,
      :comments   => request.reason || ''
    )
  end

  private

  def topic
    @topic ||= ENV['QUEUE_NAME'] || 'approval_events'.freeze
  end

  def send_event(event, payload)
    ManageIQ::Messaging::Client.open(
      :protocol => 'Kafka',
      :host     => ENV['QUEUE_HOST'] || 'localhost',
      :port     => ENV['QUEUE_PORT'] || 9092,
      :encoding => 'json'
    ) do |client|
      client.publish_topic(:service => topic, :sender => EVENT_SENDER, :event => event, :payload => payload)
    end
  rescue StandardError
    # Temporarily suppress the error for test without Kafka
    Rails.logger.error("Can't send event " + event)
  end
end
