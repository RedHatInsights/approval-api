require 'manageiq-messaging'

class EventService
  APPROVAL_EVENT_TOPIC = 'insights-approval-service'.freeze

  attr_accessor :request

  def initialize(request)
    self.request = request
  end

  def approver_group_notified(stage)
    send_event('approver_group_notified',
      :request_id => request.id,
      :group_name => stage.group.name
    )
  end

  def approver_group_finished(stage)
    send_event('approver_group_finished',
      :request_id => request.id,
      :group_name => stage.group.name,
      :decision   => stage.decision,
      :comments   => stage.comments
    )
  end

  def request_started
    send_event('request_started', :request_id => request.id)
  end

  def request_finished
    send_event('request_finished',
      :request_id => request.id,
      :decision   => request.decision,
      :comments   => request.reason || ''
    )
  end

  private

  def send_event(event, payload)
    ManageIQ::Messaging::Client.open(
      :protocol  => 'Kafka',
      :host      => ENV['INSIGHTS_KAFKA_HOST'] || 'localhost',
      :port      => ENV['INSIGHTS_KAFKA_PORT'] || 9092,
      :encoding  => 'json'
    ) do |client|
      client.publish_topic(:service => APPROVAL_EVENT_TOPIC, :sender => 'approval_api_service', :event => event, :payload => payload)
    end
  rescue StandardError
    # Temporarily suppress the error for test without Kafka
    Rails.logger.error("Can't send event " + event)
  end
end
