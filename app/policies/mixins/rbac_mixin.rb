module Mixins
  module RBACMixin
    include ApprovalPermissions

    APPROVER_VISIBLE_STATES = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE].freeze

    def resource_check(verb, record = @record)
      return true unless @user.rbac_enabled?

      klass = record.class
      return permission_check(verb, klass) unless [Request, Action].include?(klass)

      if admin?(klass, verb)
        true
      elsif approver?(klass, verb) && approver_accessible?(record) || requester?(klass, verb) && requester_accessible?(record)
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

    def approver_visible_requests(scope)
      scope.where(:group_ref => @user.group_uuids, :state => APPROVER_VISIBLE_STATES)
    end

    def scopes(klass, verb)
      access.scopes(klass.table_name, verb)
    end

    def access
      @user.access
    end

    private

    def approver_accessible?(record)
      record = record.request if record.kind_of?(Action)
      @user.group_uuids.include?(record.group_ref) && APPROVER_VISIBLE_STATES.include?(record.state)
    end

    def requester_accessible?(record)
      record = record.request if record.kind_of?(Action)
      record.owner == Insights::API::Common::Request.current.user.username
    end
  end
end
