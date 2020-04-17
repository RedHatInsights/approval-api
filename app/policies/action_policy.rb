class ActionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return graphql_id_query if graphql_query_by_id?

      if user.params[:request_id]
        req = Request.find(user.params[:request_id])
        raise Exceptions::NotAuthorizedError, "Read access not authorized for request #{req.id}" unless resource_check('read', req)

        req.actions
      else # Both GraphQL and direct access are not allowed 
        raise Exceptions::NotAuthorizedError, "Not authorized to directly access actions"
      end
    end
  end

  def create?
    permission_check('create', record) ? validate_create_action : false
  end

  def show?
    resource_check('read')
  end

  private

  def validate_create_action
    operation = user.params.require(:operation)
    uuid = user.request.headers['x-rh-random-access-key']

    valid_operation =
      admin?(record, 'create') && Action::ADMIN_OPERATIONS.include?(operation) ||
      approver?(record, 'create') && Action::APPROVER_OPERATIONS.include?(operation) ||
      requester?(record, 'create') && Action::REQUESTER_OPERATIONS.include?(operation) ||

      uuid.present? && Request.find(user.params[:request_id]).try(:random_access_keys).any? { |key| key.access_key == uuid }
  end
end
