module GroupValidateMixin
  APPROVER_ROLE = 'Approval Approver'.freeze

  def ensure_group(group_ref, context = nil)
    context ||= Insights::API::Common::Request.current.to_h.transform_keys(&:to_s)
    ContextService.new(context).as_org_admin do
      Group.find(group_ref)
    rescue RBACApiClient::ApiError => e
      raise unless e.code == 404

      raise Exceptions::UserError, "Group #{group_ref} does not exist"
    end
  end

  def validate_approver_group(group_ref)
    group = ensure_group(group_ref)
    raise Exceptions::UserError, "Group #{group.name} does not have approver role" unless group.has_role?(APPROVER_ROLE)
  end

  def validate_approver_groups(groups)
    groups.each { |group_ref| validate_approver_group(group_ref) }
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
