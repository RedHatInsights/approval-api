module RBAC
  class Access
    include RBAC::Permissions

    ADMIN_ROLE = 'Approval Administrator'.freeze
    APPROVER_ROLE = 'Approval Approver'.freeze
    APP_NAME = 'approval'.freeze

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end

    # permission level check
    def self.resource_accessible?(resource, verb)
      admin? || acls(resource, verb).any? || owner_acls(resource, verb).any?
    end

    # instance level check
    def self.resource_instance_accessible?(resource, resource_id)
      admin? || approvable?(resource, resource_id) || owned?(resource, resource_id)
    end

    # check if approver can process the #{resource} with #{id}
    def self.approvable?(resource, id)
      approver? && approver_id_list(resource)&.include?(id.to_i)
    end

    # check if regular requester own the #{resource} with #{id}
    def self.owned?(resource, id)
      owner_id_list(resource)&.include?(id.to_i)
    end

    # resource ids approver can approve
    def self.approver_id_list(resource)
      id_list(resource, approver_request_ids)
    end

    # resource ids owner owns
    def self.owner_id_list(resource)
      id_list(resource, owner_request_ids)
    end

    def self.admin?
      RBAC::Roles.assigned_role?(ADMIN_ROLE)
    end

    def self.approver?
      RBAC::Roles.assigned_role?(APPROVER_ROLE)
    end

    # Access list for the #{resource} and action #{verb}
    def self.acls(resource, verb)
      regexp = Regexp.new(":(#{resource}|\\*):(#{verb}|\\*)")
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        RBAC::Service.paginate(api, :get_principal_access, {:scope => 'principal', :limit => 500}, APP_NAME).select do |item|
          regexp.match(item.permission)
        end
      end
    end

    # Owner access list for the #{resource} and action #{verb}
    def self.owner_acls(resource, verb)
      regexp = Regexp.new(":(#{resource}|\\*):(#{verb}|\\*)")
      requester_acls.select do |item|
        regexp.match(item.permission)
      end
    end

    # current RBAC user
    def self.whoami?
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        api.api_client.config.username
      end
    end

    # Request ids owned by requester
    def self.owner_request_ids
      Request.by_owner.pluck(:id).sort
    end

    # Request ids approver can process
    def self.approver_request_ids
      Request.where(:workflow_id => workflow_ids).pluck(:id).sort
    end

    # Id list for resource #{resource}
    def self.id_list(resource, request_ids)
      case resource
      when "requests"
        request_ids
      when "stages"
        stage_ids(request_ids)
      when "actions"
        action_ids(request_ids)
      else
        raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}"
      end
    end

    # Stage ids associated with request ids #{request_ids}
    def self.stage_ids(request_ids)
      Stage.where(:request_id => request_ids).pluck(:id).sort
    end

    # Action ids associated with request ids #{request_ids}
    def self.action_ids(request_ids)
      Action.where(:stage_id => stage_ids(request_ids)).pluck(:id).sort
    end

    # The accessible workflow ids for approver
    def self.workflow_ids
      approver_acls = acls('workflows', 'approve')
      ids = SortedSet.new
      approver_acls.each do |acl|
        acl.resource_definitions.any? do |rd|
          next unless rd.attribute_filter.key == 'id'
          next unless rd.attribute_filter.operation == 'equal'

          ids << rd.attribute_filter.value.to_i
        end
      end

      Rails.logger.info("Accessible workflows: #{ids.to_a}")

      ids.to_a.sort
    end

    # The access list regular requesters have
    def self.requester_acls
      RBAC::ACLS.new.create(nil, OWNER_PERMISSIONS)
    end
  end
end
