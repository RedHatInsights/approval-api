module GroupValidateMixin
  APPROVER_ROLE = 'Approval Approver'.freeze

  def validate_approver_groups(group_refs, raise_error = true)
    not_uniq = group_refs.uniq! { |ref| ref['uuid'] }
    raise Exceptions::UserError, 'Duplicated group UUID was detected' if not_uniq && raise_error

    group_refs.collect do |group_ref|
      if raise_error
        validate_approver_group_and_raise(group_ref['uuid'])
      else
        validate_approver_group_no_raise(group_ref['uuid'], group_ref['name'])
      end
    end
  end

  def validate_and_update_approver_groups(workflow, raise_error = true)
    workflow.group_refs = validate_approver_groups(workflow.group_refs, raise_error)
    workflow.save!
  end

  def runtime_validate_group(request)
    group = nil

    begin
      group = ensure_group(request.group_ref, request.context)
    rescue Exceptions::UserError => e
      error_action(request, e.message)
    end

    return false unless group

    if group.users.empty?
      error_action(request, "Group #{group.name} is empty")
      return false
    end

    unless group.has_role?(APPROVER_ROLE)
      error_action(request, "Group #{group.name} does not have approver role")
      return false
    end

    true
  end

  private

  def ensure_group(group_ref, context = nil)
    context ||= Insights::API::Common::Request.current.to_h.transform_keys(&:to_s)
    ContextService.new(context).as_org_admin do
      Group.find(group_ref)
    rescue RBACApiClient::ApiError => e
      raise unless e.code == 404

      raise Exceptions::UserError, "Group #{group_ref} does not exist"
    end
  end

  def validate_approver_group_and_raise(uuid)
    group = ensure_group(uuid)
    raise Exceptions::UserError, "Group #{group.name} does not have approver role" unless group.has_role?(APPROVER_ROLE)

    {'name' => group.name, 'uuid' => uuid}
  end

  def validate_approver_group_no_raise(uuid, old_name)
    name = begin
             group = ensure_group(uuid)
             if group.has_role?(APPROVER_ROLE)
               group.name
             else
               "#{group.name}(No approver permission)"
             end
           rescue Exceptions::UserError
             "#{old_name}(Group does not exist)"
           rescue StandardError
             old_name
           end

    {'name' => name, 'uuid' => uuid}
  end

  def error_action(request, message)
    ActsAsTenant.with_tenant(Tenant.find(request.tenant_id)) do
      ActionCreateService.new(request.id).create(
        :operation    => Action::ERROR_OPERATION,
        :processed_by => 'system',
        :comments     => message
      )
    end
  end
end
