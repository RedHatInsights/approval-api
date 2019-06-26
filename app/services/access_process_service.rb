class AccessProcessService
  WORKFLOW_APPROVE_PERMISSION = 'approval:workflows:approve'.freeze
  ACTION_CREATE_PERMISSION    = 'approval:actions:create'.freeze
  ACTION_READ_PERMISSION    = 'approval:actions:read'.freeze
  REQUEST_READ_PERMISSION    = 'approval:requests:read'.freeze
  STAGE_READ_PERMISSION    = 'approval:stages:read'.freeze
  APPROVER_PERMISSIONS = [ACTION_CREATE_PERMISSION, ACTION_READ_PERMISSION,
                          REQUEST_READ_PERMISSION, STAGE_READ_PERMISSION].freeze

  def initialize(opts = {})
    @app_name = opts[:app_name] || 'approval'
    @prefix = opts[:role_prefix] || "#{@app_name}-group-"
    @acls = RBAC::ACLS.new
    @roles = RBAC::Roles.new(@prefix)
  end

  def add_acls(group_uuid, resource_id, permissions)
    role = find_role(group_uuid)
    raise Exceptions::ApprovalError "Role does not exist for group #{group_uuid}!" unless role

    add_role_acls(role, resource_id, permissions)
  end

  def remove_acls(group_uuid, resource_id, permissions=[WORKFLOW_APPROVE_PERMISSION])
    role = find_role(group_uuid)
    raise Exceptions::ApprovalError "Role does not exist for group #{group_uuid}!" unless role

    remove_role_acls(role, resource_id, permissions)
  end

  def update_or_create_role(group_uuid, resource_id)
    role = find_role(group_uuid)
    role ? add_role_acls(role, resource_id, [WORKFLOW_APPROVE_PERMISSION]) : create_role(group_uuid, resource_id) 
  end

  def find_role(group_uuid)
    name = "#{@prefix}#{group_uuid}"
    @roles.find(name)
  end

  def add_resource_to_groups(resource_id, group_refs)
    groups = group_refs.map { |ref| Group.find(ref) }

    groups.each do |group|
      update_or_create_role(group.uuid, resource_id)
    end
  end

  def remove_resource_from_groups(resource_id, group_refs)
    groups = group_refs.map { |ref| Group.find(ref) }

    groups.each do |group|
      remove_acls(group.uuid, resource_id)
    end
  end

  private

  def create_role(group_uuid, resource_id)
    name = "#{@prefix}#{group_uuid}"

    # create approver's default permission 
    acls = @acls.create(nil, APPROVER_PERMISSIONS)
    role = @roles.add(name, acls)

    # add approver's accessbile workflow
    add_role_acls(role, resource_id, [WORKFLOW_APPROVE_PERMISSION])
    add_policy(name, group_uuid, role.uuid)
  end

  def add_role_acls(role, resource_id, permissions)
    role.access = @acls.add(role.access, resource_id, permissions)
    @roles.update(role)
  end

  def remove_role_acls(role, resource_id, permissions)
    role.access = @acls.remove(role.access, resource_id, permissions)
    @acls.resource_defintions_empty?(role.access, WORKFLOW_APPROVE_PERMISSION) ?  @roles.delete(role) :  @roles.update(role)

    #TODO: check if need to remove policy
    #delete_policy(role)
  end

  def add_policy(name, group_uuid, role_uuid)
    RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
      policy_in = RBACApiClient::PolicyIn.new
      policy_in.name = name
      policy_in.description = 'Approval Policy'
      policy_in.group = group_uuid
      policy_in.roles = [role_uuid]
      api_instance.create_policies(policy_in)
    end
  end

  def delete_policy(role)
    RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
      RBAC::Service.paginate(api_instance, :list_policies, {:name => @prefix}).each do |policy|
        api_instance.delete_policy(policy.uuid) if policy.roles.pluck(:uuid).include?(role.uuid)
      end
    end
  end
end
