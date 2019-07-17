class AccessProcessService
  include RBAC::Permissions

  def initialize(opts = {})
    @app_name = opts[:app_name] || 'approval'
    @prefix = opts[:role_prefix] || "#{@app_name}-group-"
    @acls = RBAC::ACLS.new
    @roles = RBAC::Roles.new(@prefix)
  end

  # Add access control lists to the role for group
  def add_acls(name, resource_id, permissions)
    role = find_role(name)
    raise Exceptions::RBACError("Role [#{name}] does not exist!") unless role

    add_role_acls(role, resource_id, permissions)
  end

  def remove_acls(name, resource_id, permissions = [WORKFLOW_APPROVE_PERMISSION])
    role = find_role(name)
    raise Exceptions::RBACError("Role [#{name}] does not exist!") unless role

    remove_acls_or_delete_role(role, resource_id, permissions)
  end

  def update_or_create_role(name, resource_id, permissions = [WORKFLOW_APPROVE_PERMISSION])
    role = find_role(name)

    role ? add_role_acls(role, resource_id, permissions) : create_role(name, resource_id, permissions)
  end

  def find_role(name)
    @roles.find(name)
  end

  def add_resource_to_groups(resource_id, group_refs)
    group_refs.each do |uuid|
      name = "#{@prefix}#{uuid}"
      update_or_create_role(name, resource_id)
    end
  end

  def remove_resource_from_groups(resource_id, group_refs)
    group_refs.each do |uuid|
      name = "#{@prefix}#{uuid}"
      remove_acls(name, resource_id)
    end
  end

  private

  def create_role(name, resource_id, permissions)
    acls = @acls.create(resource_id, permissions)
    role = @roles.add(name, acls)

    add_policy(name, role.uuid)

    role
  end

  def add_role_acls(role, resource_id, permissions = [WORKFLOW_APPROVE_PERMISSION])
    role.access = @acls.add(role.access, resource_id, permissions)
    @roles.update(role)
  end

  def remove_acls_or_delete_role(role, resource_id, permissions)
    role.access = @acls.remove(role.access, resource_id, permissions)

    if @acls.resource_defintions_empty?(role.access, WORKFLOW_APPROVE_PERMISSION)
      delete_policy(role)
      @roles.delete(role)
    else
      @roles.update(role)
    end
  end

  def add_policy(name, role_uuid)
    RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
      policy_in = RBACApiClient::PolicyIn.new
      policy_in.name = name
      policy_in.description = 'Approval Policy'
      policy_in.group = name.split('group-')[1]
      policy_in.roles = [role_uuid]
      api_instance.create_policies(policy_in)
    end
  end

  def delete_policy(role)
    RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
      RBAC::Service.paginate(api_instance, :list_policies, :name => @prefix).each do |policy|
        api_instance.delete_policy(policy.uuid) if policy.roles.pluck(:uuid).include?(role.uuid)
      end
    end
  end
end
