class RequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    PERSONA_ADMIN     = 'approval/admin'.freeze
    PERSONA_APPROVER  = 'approval/approver'.freeze
    PERSONA_REQUESTER = 'approval/requester'.freeze

    def resolve
      return scope.all unless user.rbac_enabled?
      klass = scope == Request ? scope : scope.model

      case Insights::API::Common::Request.current.headers[Insights::API::Common::Request::PERSONA_KEY]
      when PERSONA_ADMIN
        raise Exceptions::NotAuthorizedError, "No permission to access the complete list of requests" unless admin?(klass)
        scope == Request ? scope.where(:parent_id => nil) : scope
      when PERSONA_APPROVER
        raise Exceptions::NotAuthorizedError, "No permission to access requests assigned to approvers" unless approver?(klass)
        scope.where(:id => approver_id_list(scope.table_name))
      when PERSONA_REQUESTER, nil
        scope == Request ? scope.where(:parent_id => nil, :id => owner_id_list(scope.table_name)) : scope
      else
        raise Exceptions::NotAuthorizedError, "Unknown persona"
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

  # only for child requests
  def index?
    resource_check('read', record.id, record.class)
  end
 
  # define for graphql
  def query?
    permission_check('read', record)
  end
end
