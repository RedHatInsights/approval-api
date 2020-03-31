module Api
  module V1x0
    class ActionsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin
      include Api::V1x0::Mixins::RBACMixin

      ADMIN_OPERATIONS     = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION, Action::CANCEL_OPERATION].freeze
      APPROVER_OPERATIONS  = [Action::MEMO_OPERATION, Action::APPROVE_OPERATION, Action::DENY_OPERATION].freeze
      REQUESTER_OPERATIONS = [Action::CANCEL_OPERATION].freeze

      before_action :read_access_check, :only => %i[show]
      before_action :create_access_check, :validate_create_action, :only => %i[create]

      def index
        req = Request.find(params.require(:request_id))

        collection(index_scope(req.actions))
      end

      def show
        action = Action.find(params.require(:id))

        json_response(action)
      end

      def create
        action = ActionCreateService.new(params.require(:request_id)).create(params_for_create)

        json_response(action, :created)
      end

      private

      def validate_create_action
        operation = params.require(:operation)
        uuid = request.headers['x-rh-random-access-key']

        valid_operation =
          admin? && ADMIN_OPERATIONS.include?(operation) ||
          approver? && APPROVER_OPERATIONS.include?(operation) ||
          requester? && REQUESTER_OPERATIONS.include?(operation) ||
          uuid.present? && RandomAccessKey.find_by(:access_key => uuid)

        raise Exceptions::NotAuthorizedError, "Not authorized to create [#{operation}] action " unless valid_operation

        resource_check('read', params[:request_id], Request) # NotAuthorizedError if current user cannot access the particular request
      end

      def rbac_scope(relation)
        return relation if admin?

        # Only approver can reach here
        resource_check('read', params[:request_id], Request) # NotAuthorizedError if current user cannot access the particular request

        action_ids = approver_id_list(relation.model.table_name)
        Rails.logger.debug { "Approver scope for actions: #{action_ids}" }

        relation.where(:id => action_ids)
      end
    end
  end
end
