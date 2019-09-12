module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]
      before_action :create_access_check, :only => %i[create]

      def index
        stage = Stage.find(params.require(:stage_id))

        RBAC::Access.enabled? ? collection(rbac_scope(stage.actions)) : collection(stage.actions)
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
