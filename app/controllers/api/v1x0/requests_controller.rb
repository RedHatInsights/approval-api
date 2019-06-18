module Api
  module V1x0
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
    end
  end
end
