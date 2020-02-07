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
  end

  def signal(decision)
    options = substitute_password(template.signal_setting)
    Kie::Service.call(KieClient::ProcessInstancesBPMApi, options) do |bpm|
      bpm.signal_process_instance(options['container_id'], request.process_ref, options['signal_name'], :body => signal_options(decision))
    end
  end

  def valid_request?
    ContextService.new(request.context).as_org_admin do
      group = Group.find(request.group_ref)

      if request.workflow.group_refs.empty? || group.users.empty? || !group.exists? || !group.has_role?('Approval Approver')
        ActsAsTenant.with_tenant(Tenant.find(request.tenant_id)) do
          ActionCreateService.new(request.id).create(
            :operation    => Action::ERROR_OPERATION,
            :processed_by => 'system',
            :comments     => 'Invalid groups, either not exist or no approver role assigned'
          )
        end

        return false
      end
    end
    true
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
        'groups'          => [group].as_json
      }
    end
    options
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
