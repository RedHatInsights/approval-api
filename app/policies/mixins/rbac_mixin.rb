module Mixins
  module RBACMixin
    include Insights::API::Common::RBAC
    include ApprovalPermissions

    def resource_check(verb, id = @record.id, klass = @record.class)
      permission_check(verb, klass) ? resource_instance_accessible?(klass.table_name, id) : false
    end

    def permission_check(verb, resource = @record)
      return true unless Insights::API::Common::RBAC::Access.enabled?

      klass = resource_class(resource)
      access.accessible?(klass.table_name, verb, 'approval')
    end

    # instance level check
    def resource_instance_accessible?(resource, resource_id)
      return true if admin?

      approver? && approvable?(resource, resource_id) || requester? && owned?(resource, resource_id)
    end

    def admin?(resource = @record)
      return false unless Insights::API::Common::RBAC::Access.enabled?

      klass = resource_class(resource)
      access.scopes(klass.table_name, 'read').include?('admin')
    end

    def approver?(resource = @record)
      return false unless Insights::API::Common::RBAC::Access.enabled?

      klass = resource_class(resource)
      access.scopes(klass.table_name, 'read').include?('group')
    end

    def requester?(resource = @record)
      !admin?(resource) && !approver?(resource)
    end

    # check if approver can process the #{resource} with #{id}
    def approvable?(resource, id)
      approver_id_list(resource)&.include?(id.to_i)
    end

    # check if regular requester own the #{resource} with #{id}
    def owned?(resource, id)
      owner_id_list(resource)&.include?(id.to_i)
    end

    # resource ids approver can access
    def approver_id_list(resource)
      visible_request_ids = visible_request_ids_for_approver
      Rails.logger.debug { "Final accessible request ids: #{visible_request_ids}" }

      case resource
      when "requests"
        visible_request_ids
      when "actions"
        Action.where(:request_id => visible_request_ids).pluck(:id).sort
      else
        raise ArgumentError, "Unknown resource type: #{resource}"
      end
    end

    # resource ids owner owns
    def owner_id_list(resource)
      case resource
      when "requests"
        owner_request_ids
      when "actions"
        Action.where(:request_id => owner_request_ids).pluck(:id).sort
      else
        raise ArgumentError, "Unknown resource type: #{resource}"
      end
    end

    def owner_request_ids
      Request.by_owner.pluck(:id).sort
    end

    # All child request ids for approver to process
    def visible_request_ids_for_approver
      visible_states = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE]
      Request.where(:workflow_id => workflow_ids, :state => visible_states).pluck(:id)
    end

    def assigned_group_refs
      Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
      end
    end

    # The accessible workflow ids for approver
    def workflow_ids
      AccessControlEntry.where(:aceable_type => 'Workflow', :permission => 'approve', :group_uuid => assigned_group_refs).pluck(:aceable_id)
    end

    def access
      @access ||= Insights::API::Common::RBAC::Access.new('approval').process
    end

    def resource_class(resource)
      if resource.class == Class
        resource
      elsif resource.respond_to?(:model)
        resource.model
      elsif resource.instance_of?(resource.class)
        resource.class
      else
        raise ArgumentError, "Unknown resource type: #{resource} in permission check"
      end
    end
  end
end
