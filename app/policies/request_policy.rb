class RequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    PERSONA_ADMIN     = 'approval/admin'.freeze
    PERSONA_APPROVER  = 'approval/approver'.freeze
    PERSONA_REQUESTER = 'approval/requester'.freeze

    def resolve
      return scope.all unless user.rbac_enabled?

      if user.params[:request_id]
        req = Request.find(user.params[:request_id])
        raise Exceptions::NotAuthorizedError, "Read access not authorized for request #{req.id}" unless resource_check('read', req)
        req.children
      # GraphQL comes in with model_class.all, whose scope is respond to model call
      # Regular root requests call comes in with model class itself
      else
        case Insights::API::Common::Request.current.headers[Insights::API::Common::Request::PERSONA_KEY]
        when PERSONA_ADMIN
          raise Exceptions::NotAuthorizedError, "No permission to access the complete list of requests" unless admin?(scope)
          scope.respond_to?(:model) ? scope : scope.where(:parent_id => nil)
        when PERSONA_APPROVER
          raise Exceptions::NotAuthorizedError, "No permission to access requests assigned to approvers" unless approver?(scope)
          scope.respond_to?(:model) ? (raise Exceptions::NotAuthorizedError, "Approver not allowed to access requests via GraphQL") :
                                      approver_visible_requests(scope)
        when PERSONA_REQUESTER, nil
          scope.respond_to?(:model) ? scope.by_owner : scope.by_owner.where(:parent_id => nil)
        else
          raise Exceptions::NotAuthorizedError, "Unknown persona"
        end
      end
    end
  end

  def create?
    klass = record.class == Request ? record.class : record
    permission_check('create', klass)
  end

  def show?
    resource_check('read')
  end

  def user_capabilities
    super.merge(valid_actions_hash)
  end

  def valid_actions_hash
    hash = { Action::APPROVE_OPERATION => false,
             Action::CANCEL_OPERATION  => false,
             Action::DENY_OPERATION    => false,
             Action::MEMO_OPERATION    => true }

   actions = valide_actions_on_roles & valid_actions_on_state

    # only child request can be approved/denied
    actions -= [Action::APPROVE_OPERATION, Action::DENY_OPERATION] if record.parent?
    # only root can be cancelled
    actions -= [Action::CANCEL_OPERATION] unless record.root?

    actions.map { |action| hash[action] = true }

    hash
  end

  private

  def valid_actions_on_state(state = record.state)
    {
      Request::PENDING_STATE   => [Action::START_OPERATION, Action::SKIP_OPERATION, Action::CANCEL_OPERATION, Action::ERROR_OPERATION],
      Request::STARTED_STATE   => [Action::NOTIFY_OPERATION, Action::ERROR_OPERATION, Action::CANCEL_OPERATION],
      Request::NOTIFIED_STATE  => [Action::APPROVE_OPERATION, Action::DENY_OPERATION, Action::CANCEL_OPERATION, Action::ERROR_OPERATION],
      Request::SKIPPED_STATE   => [Action::MEMO_OPERATION],
      Request::FAILED_STATE    => [Action::MEMO_OPERATION],
      Request::COMPLETED_STATE => [Action::MEMO_OPERATION],
      Request::CANCELED_STATE  => [Action::MEMO_OPERATION]
    }[state]
  end

  def valide_actions_on_roles
    operations = []
    operations |= Action::ADMIN_OPERATIONS if admin?(record.class)
    operations |= Action::APPROVER_OPERATIONS if approver?(record.class)
    operations |= Action::REQUESTER_OPERATIONS if requester?(record.class)

    operations
  end
end
