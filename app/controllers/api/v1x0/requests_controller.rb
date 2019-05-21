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
        validate_filters

        reqs = if params[:workflow_id]
                 Request.includes(:stages).where(:workflow_id => params.require(:workflow_id))
               elsif params[:approver]
                 RequestListByApproverService.new(params.require(:approver)).list
               else
                 Request.includes(:stages)
               end

        collection(reqs)
      rescue Exceptions::ApprovalError => e
        json_response({ :message => e.message }, :unprocessable_entity)
      end

      private

      def validate_filters
        state = params.dig(:filter, :state)
        decision = params.dig(:filter, :decision)
        raise Exceptions::ApprovalError, "Invalid filter on state: #{state}" if state && ApprovalStates::STATES.exclude?(state)
        raise Exceptions::ApprovalError, "Invalid filter on decision: #{decision}" if decision && ApprovalDecisions::DECISIONS.exclude?(decision)
      end

      def request_params
        params.permit(:name, :requester, :content => {})
      end
    end
  end
end
