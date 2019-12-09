class AccessProcessService
  include ApprovalPermissions

  APPROVER_ROLE_PREFIX = 'approval-group-'.freeze

  # Need to call as org admin
  def initialize
    @acls = Insights::API::Common::RBAC::ACL.new
    @roles = Insights::API::Common::RBAC::Roles.new(APPROVER_ROLE_PREFIX, 'account')
  end

  # Need to call as org admin
  def add_resource_to_groups(resource_id, group_refs, permissions = [WORKFLOW_APPROVE_PERMISSION])
    group_refs.each do |uuid|
      name = "#{APPROVER_ROLE_PREFIX}#{uuid}"
      update_or_create_role(name, resource_id, permissions)
    end
  end

  # Need to call as org admin
  def remove_resource_from_groups(resource_id, group_refs, permissions = [WORKFLOW_APPROVE_PERMISSION])
    group_refs.each do |uuid|
      name = "#{APPROVER_ROLE_PREFIX}#{uuid}"
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
      group_ref = role.name.delete_prefix(APPROVER_ROLE_PREFIX)
      Group.find(group_ref).add_role(role.uuid)
    end
  end

  def add_role_acls(role, resource_id, permissions)
    role.access = @acls.add(role.access, resource_id, permissions)
    @roles.update(role)
  end

  def remove_acls_or_delete_role(role, resource_id, permissions)
    role.access = @acls.remove(role.access, resource_id, permissions)

    if @acls.resource_defintions_empty?(role.access, WORKFLOW_APPROVE_PERMISSION)
      group_ref = role.name.delete_prefix(APPROVER_ROLE_PREFIX)
      Group.find(group_ref).delete_role(role.uuid)
      @roles.delete(role)
    else
      @roles.update(role)
    end
  end
end
