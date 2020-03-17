class ActionPolicy < ApplicationPolicy
  include Mixins::RBACMixin

  ADMIN_OPERATIONS     = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION, Action::CANCEL_OPERATION].freeze
  APPROVER_OPERATIONS  = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION].freeze
  REQUESTER_OPERATIONS = [Action::CANCEL_OPERATION].freeze

  class Scope
    include Mixins::RBACMixin

    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      permission_check('read')
      return scope.all if admin?

      # Only approver can reach here
      resource_check('read', user.params[:request_id], Request) # NotAuthorizedError if current user cannot access the particular request

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
    permission_check('read', record)
  end

  private

  def validate_create_action
    operation = user.params.require(:operation)
    uuid = user.request.headers['x-rh-random-access-key']

    valid_operation =
      admin? && ADMIN_OPERATIONS.include?(operation) ||
      approver? && APPROVER_OPERATIONS.include?(operation) ||
      requester? && REQUESTER_OPERATIONS.include?(operation) ||
      uuid.present? && Request.find_by(:random_access_key => uuid)

    raise Exceptions::NotAuthorizedError, "Not authorized to create [#{operation}] action " unless valid_operation

    resource_check('read', user.params[:request_id], Request) # NotAuthorizedError if current user cannot access the particular request
  end
end
