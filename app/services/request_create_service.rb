class RequestCreateService
  require 'securerandom'

  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def create(options)
    stages = workflow.group_refs.collect do |group_ref|
      Stage.new(
        :group_ref         => group_ref,
        :state             => Stage::PENDING_STATE,
        :decision          => Stage::UNDECIDED_STATUS,
        :random_access_key => SecureRandom.hex(16)
      )
    end

    create_options = options.merge(
      :workflow => workflow,
      :state    => Request::PENDING_STATE,
      :decision => Request::UNDECIDED_STATUS,
      :stages   => stages
    )
    Request.create!(create_options).tap do |request|
      if default_approve? || auto_approve?
        start_internal_approval_process(request)
      elsif !workflow.external_processing?
        start_first_stage(request)
      else
        start_external_approval_process(request)
      end
    end
  end

  private

  def default_approve?
    workflow.id == Workflow.default_workflow.try(:id)
  end

  def auto_approve?
    ENV['AUTO_APPROVAL'] && ENV['AUTO_APPROVAL'] != 'n'
  end

  def start_internal_approval_process(request)
    Thread.new do
      ContextService.new(request.context).with_context do
        default_approve? ? default_approve(request) : auto_approve(request)
      end
    end
  end

  def auto_approve(request)
    sleep_time = ENV['AUTO_APPROVAL_INTERVAL'].to_f

    start_first_stage(request)
    request.stages.each { |stage| group_auto_approve(stage, sleep_time) }
  end

  def group_auto_approve(stage, sleep_time)
    sleep(sleep_time)
    ActionCreateService.new(stage.id).create(
      'operation'    => Action::APPROVE_OPERATION,
      'processed_by' => 'system',
      'comments'     => 'ok'
    )
  end

  def default_approve(request)
    request_started(request)
    request_finished(request)
  end

  def request_started(request)
    RequestUpdateService.new(request.id).update(
      :state    => Request::NOTIFIED_STATE
    )
  end

  def request_finished(request)
    RequestUpdateService.new(request.id).update(
      :state    => Request::FINISHED_STATE,
      :decision => Request::APPROVED_STATUS,
      :reason   => 'System approved'
    )
  end

  def start_first_stage(request)
    request_started(request)
    ActionCreateService.new(request.stages.first.id).create(
      :operation    => Action::NOTIFY_OPERATION,
      :processed_by => 'system'
    )
  end

  def start_external_approval_process(request)
    template = request.workflow.template
    processor_class = "#{template.process_setting['processor_type']}_process_service".classify.constantize
    ref = processor_class.new(request).start
    request.update_attributes(:process_ref => ref)
    request_started(request)
  end
end
