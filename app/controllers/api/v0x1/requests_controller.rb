module Api
  module V0x1
    class RequestsController < ApplicationController
      include Mixins::IndexMixin

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
          collection(workflow.requests)
        elsif params[:user_id]
          user = Workflow.find(params.require(:user_id))
          collection(user.requests)
        else
          reqs = Request.filter(params.slice(:requester, :decision, :state))
          collection(reqs)
        end
      end

      private

      def request_params
        params.permit(:name, :requester, :content, :limit, :offset)
      end
    end
  end
end
