class ActionPolicy < ApplicationPolicy

  ADMIN_OPERATIONS     = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION, Action::CANCEL_OPERATION].freeze
  APPROVER_OPERATIONS  = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION].freeze
  REQUESTER_OPERATIONS = [Action::CANCEL_OPERATION].freeze

  class Scope < ApplicationPolicy::Scope
    def resolve
      raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}" unless permission_check('read', scope)
      return scope.all if admin?(scope.model)

      action_ids = approver_id_list(scope.model.table_name)
      Rails.logger.debug { "Approver scope for actions: #{action_ids}" }

      scope.where(:id => action_ids)
    end
  end

  def create?
    permission_check('create')
    validate_create_action
  end

  def show?
    resource_check('read')
  end

  def query?
    permission_check('read')
  end

  private

  def validate_create_action
    operation = user.params.require(:operation)
    uuid = user.request.headers['x-rh-random-access-key']

    valid_operation =
      admin?(record, 'create') && ADMIN_OPERATIONS.include?(operation) ||
      approver?(record, 'create') && APPROVER_OPERATIONS.include?(operation) ||
      requester?(record, 'create') && REQUESTER_OPERATIONS.include?(operation) ||

      uuid.present? && Request.find(user.params[:request_id]).try(:random_access_keys).any? { |key| key.access_key == uuid }
  end
end
