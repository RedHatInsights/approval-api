class ActionPolicy < ApplicationPolicy

  ADMIN_OPERATIONS     = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION, Action::CANCEL_OPERATION].freeze
  APPROVER_OPERATIONS  = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION].freeze
  REQUESTER_OPERATIONS = [Action::CANCEL_OPERATION].freeze

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Must through a request
      raise Exceptions::NotAuthorizedError, "Not authorized to directly access actions" if scope == Action
      scope
    end
  end

  def create?
    permission_check('create', record)
    validate_create_action
  end

  def show?
    resource_check('read')
  end

  def query?
    permission_check('read', record)
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
