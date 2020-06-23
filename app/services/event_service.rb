require 'manageiq-messaging'

class EventService
  EVENT_REQUEST_STARTED   = 'request_started'.freeze
  EVENT_REQUEST_COMPLETED = 'request_finished'.freeze
  EVENT_REQUEST_CANCELED  = 'request_canceled'.freeze
  EVENT_APPROVER_GROUP_NOTIFIED = 'approver_group_notified'.freeze
  EVENT_APPROVER_GROUP_FINISHED = 'approver_group_finished'.freeze
  EVENT_WORKFLOW_DELETED = 'workflow_deleted'.freeze
  EVENT_SENDER = 'approval_service'.freeze

  attr_accessor :request

  def initialize(request)
    self.request = request
  end

  # request is leaf node
  def approver_group_notified
    return unless request.group_name

    send_event(EVENT_APPROVER_GROUP_NOTIFIED,
               :request_id => request.root.id,
               :group_name => request.group_name)
  end

  # request is leaf node
  def approver_group_finished
    return unless request.group_name

    send_event(EVENT_APPROVER_GROUP_FINISHED,
               :request_id => request.root.id,
               :group_name => request.group_name,
               :decision   => request.decision,
               :reason     => request.reason || '')
  end

  def workflow_deleted(workflow_id)
    send_event(EVENT_WORKFLOW_DELETED, :workflow_id => workflow_id)
  end

  # request is root
  def request_started
    send_event(EVENT_REQUEST_STARTED, :request_id => request.id)
  end

  # request is root
  def request_completed
    send_event(EVENT_REQUEST_COMPLETED,
               :request_id => request.id,
               :decision   => request.decision,
               :reason     => request.reason || '')
  end

  # request is root
  def request_canceled
    send_event(EVENT_REQUEST_CANCELED,
               :request_id => request.id,
               :reason     => request.reason || '')
  end

  private

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
      client.publish_topic(:service => topic, :sender => EVENT_SENDER, :event => event, :payload => payload, :headers => request.request_context['context']['headers'])
    end
  rescue StandardError, RBACApiClient::ApiError => error
    Rails.logger.error("Event sending failed. Reason: #{error.message}")
  end
end
