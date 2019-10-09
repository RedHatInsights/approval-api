module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]
      before_action :create_access_check, :validate_create_action, :only => %i[create]

      def index
        stage = Stage.find(params.require(:stage_id))

        collection(index_scope(stage.actions))
      end

      def show
        action = Action.find(params.require(:id))

        json_response(action)
      end

      def create
        stage_id = if params[:request_id]
                     req = Request.find(params[:request_id])
                     current_stage = req.current_stage
                     raise Exceptions::InvalidStateTransitionError, "Request has finished its lifecycle. No more action can be added to its current stage." unless current_stage

                     current_stage.id
                   else
                     params.require(:stage_id)
                   end

        action = ActionCreateService.new(stage_id).create(action_params)
        json_response(action, :created)
      end

      private

      # Different roles can only create certain kind of actions
      #   admin:     can create all kinds of actions
      #   approver:  can not create 'cancel' action
      #   requester: can only create 'cancel' action
      def validate_create_action
        operation = params[:operation]
        valid_operation = admin? || (approver? && operation != Action::CANCEL_OPERATION) || (!admin? && !approver? && operation == Action::CANCEL_OPERATION)
        raise Exceptions::NotAuthorizedError, "Not authorized to create [#{operation}] action " unless valid_operation
      end

      def action_params
        params.permit(:operation, :processed_by, :comments)
      end

      def rbac_scope(relation)
        return relation if admin?

        # Only approver can reach here
        action_ids = approver_id_list(relation.model.table_name)
        Rails.logger.info("approver scope for actions: #{action_ids}")

        relation.where(:id => action_ids)
      end
    end
  end
end
