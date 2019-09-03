module RBAC
  class Policies
    def initialize(prefix)
      @prefix = prefix
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

    # delete all policies that contains the role.
    def delete_policy(role)
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_policies, :name => @prefix, :limit => 500).each do |policy|
          api_instance.delete_policy(policy.uuid) if policy.roles.map(&:uuid).include?(role.uuid)
        end
      end
    end
  end
end
