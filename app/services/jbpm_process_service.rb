class JbpmProcessService
  attr_accessor :request

  def initialize(request)
    self.request = request
  end

  def start
    options = template.process_setting
    Kie::Service.call(KieClient::ProcessInstancesBPMApi, options) do |bpm|
      bpm.start_process(options['container_id'], options['process_id'], :body => process_options)
    end
  end

  def signal(decision)
    options = template.signal_setting
    Kie::Service.call(KieClient::ProcessInstancesBPMApi, options) do |bpm|
      bpm.signal_process_instance(options['container_id'], request.process_ref, options['signal_name'], :body => signal_options(decision))
    end
  end

  private

  def template
    request.workflow.template
  end

  def process_options
    # TODO: more options
    request.content
  end

  def signal_options(decision)
    # TODO: more options
    {'decision' => decision}
  end
end
