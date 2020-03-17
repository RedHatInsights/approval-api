module Mixins
  module RBACMixin
    include ApprovalPermissions

    ADMIN_VERB    = 'admin'.freeze
    APPROVER_VERB = 'approve'.freeze

    # Klass here is allowed for Request and Action.
    def resource_check(verb, id = @user.params[:id], klass = @user.controller_name.classify.constantize)
      permission_check(verb, klass)

      resource_instance_accessible?(klass.table_name, id) ? true : (raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass} with id: #{id}")
    end

    def permission_check(verb, klass = @user.controller_name.classify.constantize)
      return true unless Insights::API::Common::RBAC::Access.enabled?

      Insights::API::Common::RBAC::Access.new(klass.table_name, verb).process.accessible? ? true : (raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass.table_name}")
    end

    # instance level check
    def resource_instance_accessible?(resource, resource_id)
      return true if admin?

      approver? ? approvable?(resource, resource_id) : owned?(resource, resource_id)
    end

    def admin?(klass = @user.controller_name.classify.constantize)
      return false unless Insights::API::Common::RBAC::Access.enabled?

      Insights::API::Common::RBAC::Access.new(klass.table_name, ADMIN_VERB).process.accessible? ? true : false
    end

    def approver?(klass = @user.controller_name.classify.constantize)
      return false unless Insights::API::Common::RBAC::Access.enabled?

      Insights::API::Common::RBAC::Access.new(klass.table_name, APPROVER_VERB).process.accessible? ? true : false
    end

    def requester?(klass = @user.controller_name.classify.constantize)
      !admin?(klass) && !approver?(klass)
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
  end
end
