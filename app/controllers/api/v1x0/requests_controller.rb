module Api
  module V1x0
    class RequestsController < ApplicationController
      include Mixins::IndexMixin

      def create
        if params[:request_id]
          req = Request.find(params.require(:request_id))
          current_stage = req.current_stage
          raise Exceptions::ApprovalError, "Request has finished its lifecycle. No more action can be added to its current stage." unless current_stage

          action = ActionCreateService.new(current_stage.id).create(action_params)
          json_response(action, :created)
        else
          req = RequestCreateService.new(params.require(:workflow_id)).create(request_params)
          json_response(req, :created)
        end
      end

      def show
        req = Request.find(params.require(:id))
        json_response(req)
      end

      def index
        reqs = if params[:workflow_id]
                 Request.includes(:stages).where(:workflow_id => params.require(:workflow_id))
               elsif params[:approver]
                 RequestListByApproverService.new(params.require(:approver)).list
               else
                 Request.includes(:stages)
               end

        collection(reqs)
      end

      private

      def request_params
        params.permit(:name, :description, :requester, :content => {})
      end

      def action_params
        params.permit(:operation, :processed_by, :comments)
      end
    end
  end
end
