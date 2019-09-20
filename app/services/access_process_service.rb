class AccessProcessService
  include RBAC::Permissions

  # Need to call as org admin
  def initialize(opts = {})
    @app_name = ENV["APP_NAME"] || 'approval'
    @prefix = opts[:role_prefix] || "#{@app_name}-group-"
    @acls = RBAC::ACLS.new
    @roles = RBAC::Roles.new(@prefix, 'account')
    @policies = RBAC::Policies.new(@prefix)
  end

  # Need to call as org admin
  def add_resource_to_groups(resource_id, group_refs, permissions = [WORKFLOW_APPROVE_PERMISSION])
    group_refs.each do |uuid|
      name = "#{@prefix}#{uuid}"
      update_or_create_role(name, resource_id, permissions)
    end
  end

  # Need to call as org admin
  def remove_resource_from_groups(resource_id, group_refs, permissions = [WORKFLOW_APPROVE_PERMISSION])
    group_refs.each do |uuid|
      name = "#{@prefix}#{uuid}"
      remove_acls(name, resource_id, permissions)
    end
  end

  private

  # Add access control lists to the role for group
  def add_acls(name, resource_id, permissions)
    role = find_role(name)
    raise Exceptions::RBACError("Role [#{name}] does not exist!") unless role

    add_role_acls(role, resource_id, permissions)
  end

  def remove_acls(name, resource_id, permissions)
    role = find_role(name)
    raise Exceptions::RBACError("Role [#{name}] does not exist!") unless role

    remove_acls_or_delete_role(role, resource_id, permissions)
  end

  def update_or_create_role(name, resource_id, permissions)
    role = find_role(name)

    role ? add_role_acls(role, resource_id, permissions) : create_role(name, resource_id, permissions)
  end

  def find_role(name)
    @roles.find(name)
  end

  def create_role(name, resource_id, permissions)
    acls = @acls.create(resource_id, permissions)
    @roles.add(name, acls).tap do |role|
      @policies.add_policy(name, role.uuid)
    end
  end

  def add_role_acls(role, resource_id, permissions)
    role.access = @acls.add(role.access, resource_id, permissions)
    @roles.update(role)
  end

  def remove_acls_or_delete_role(role, resource_id, permissions)
    role.access = @acls.remove(role.access, resource_id, permissions)

    if @acls.resource_defintions_empty?(role.access, WORKFLOW_APPROVE_PERMISSION)
      @policies.delete_policy(role)
      @roles.delete(role)
    else
      @roles.update(role)
    end
  end
end
