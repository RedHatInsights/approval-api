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
        if params[:approver]
          return index_by_approver
        end

        Workflow.find(params.require(:workflow_id)) if params[:workflow_id] # to validate the workflow exists
        reqs = Request.includes(:stages).filter(params.slice(:requester, :decision, :state, :workflow_id))
        collection(reqs)
      end

      def index_by_approver
        username = params.require(:approver)
        group_refs = Group.all(username).map(&:uuid)

        reqs = []
        group_refs.each do |group_ref|
          reqs |= Request.all.select do |req|
            req.workflow.group_refs.include?(group_ref)
          end
        end

        collection(Request.includes(:stages).where(:id => reqs.pluck(:id)))
      end

      private

      def request_params
        params.permit(:name, :requester, :content => {})
      end
    end
  end
end
