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
        Workflow.find(params.require(:workflow_id)) if params[:workflow_id] # to validate the workflow exists
        reqs = Request.includes(:stages).filter(params.slice(:requester, :decision, :state, :workflow_id))
        collection(reqs)
      end

      private

      def request_params
        params.permit(:name, :requester, :content => {})
      end
    end
  end
end
