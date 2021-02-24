class JbpmProcessService
  attr_accessor :request

  def initialize(request)
    self.request = request
  end

  def start
    options = substitute_password(template.process_setting)
    Kie::Service.call(KieClient::ProcessInstancesBPMApi, options) do |bpm|
      bpm.start_process(options['container_id'], options['process_id'], :body => process_options)
    end
  rescue => err
    ActionCreateService.new(request.id).create(:operation => Action::ERROR_OPERATION, :processed_by => 'system', :comments => err.message)
    raise
  end

  def signal(decision)
    options = substitute_password(template.signal_setting)
    Kie::Service.call(KieClient::ProcessInstancesBPMApi, options) do |bpm|
      bpm.signal_process_instance(options['container_id'], request.process_ref, options['signal_name'], :body => signal_options(decision))
    end
  rescue => err
    # Signaling PAM is the last step after the approval has finished. Ignore the error if signal fails
    Rails.logger.error("Failed to signal PAM with error: #{err.message}")
  end

  private

  def template
    request.workflow.template
  end

  def process_options
    options = nil
    ContextService.new(request.context).as_org_admin do
      group = Group.find(request.group_ref)

      options = {
        'request'         => request,
        'request_context' => request.request_context.as_json,
        'groups'          => enhance_groups([group].as_json)
      }
    end
    options
  end

  def enhance_groups(groups_json)
    random_access_keys = []
    groups_json.each do |group_json|
      group_json['users']&.each do |user_json|
        full_name = "#{user_json['first_name']} #{user_json['last_name']}"
        random_access_key = RandomAccessKey.new(:approver_name => full_name)
        user_json['random_access_key'] = random_access_key.access_key
        random_access_keys << random_access_key
      end
    end
    request.random_access_keys = random_access_keys

    groups_json
  end

  def signal_options(decision)
    {'decision' => decision}
  end

  def substitute_password(options)
    secret_id = options['password']
    options['password'] = Encryption.find(secret_id).secret
    options
  end
end
