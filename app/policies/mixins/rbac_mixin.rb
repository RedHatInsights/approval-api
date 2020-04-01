module Mixins
  module RBACMixin
    include ApprovalPermissions

    APPROVER_VISIBLE_STATES = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE].freeze

    def resource_check(verb, id = @record.id, klass = @record.class)
      return true unless @user.rbac_enabled?

      if admin?(klass, verb)
        true
      elsif approver?(klass, verb) && approvable?(klass.table_name, id) || requester?(klass, verb) && owned?(klass.table_name, id)
        true
      else
        false
      end
    end

    def permission_check(verb, klass = @record.class)
      return true unless @user.rbac_enabled?

      access.accessible?(klass.table_name, verb)
    end

    def admin?(klass = @record.class, verb = 'read')
      scopes(klass, verb).include?("admin")
    end

    def approver?(klass = @record.class, verb = 'read')
      scopes(klass, verb).include?("group")
    end

    def requester?(klass = @record.class, verb = 'read')
      scopes(klass, verb).include?("user")
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
      Request.where(:group_ref => @user.group_uuids, :state => APPROVER_VISIBLE_STATES).pluck(:id)
    end

    def scopes(klass, verb)
      access.scopes(klass.table_name, verb)
    end
    
    def access
      @user.access
    end
  end
end
