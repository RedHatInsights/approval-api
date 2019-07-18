module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin
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
                     raise Exceptions::ApprovalError, "Request has finished its lifecycle. No more action can be added to its current stage." unless current_stage

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
        access_obj = RBAC::Access.new('actions', 'read').process
        return relation if access_obj.admin?

        raise Exceptions::NotAuthorizedError, "Not Authorized to list actions" unless access_obj.approver? || access_obj.accessible?

        action_ids = access_obj.approver_id_list
        Rails.logger.info("approver scope for actions: #{action_ids}")

        relation.where(:id => action_ids)
      end
    end
  end
end
