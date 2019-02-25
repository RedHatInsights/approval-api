module Api
  module V0x1
    class RequestsController < ApplicationController
      def create
        req = RequestCreateService.new(params.require(:workflow_id)).create(request_params)
        json_response(req, :created)
      end

      def show
        req = Request.find(params.require(:id))
        json_response(req)
      end

      def index
        if params[:workflow_id]
          workflow = Workflow.find(params.require(:workflow_id))
          json_response(workflow.requests)
        elsif params[:user_id]
          user = Workflow.find(params.require(:user_id))
          json_response(user.requests)
        else
          reqs = Request.filter(params.slice(:requester, :decision, :state))
          json_response(reqs)
        end
      end

      private

      def request_params
        params.permit(:name, :requester, :content)
      end
    end
  end
end
