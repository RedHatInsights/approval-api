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

        RBAC::Access.enabled? ? collection(rbac_scope(reqs)) : collection(reqs)
      end

      private

      def request_params
        params.permit(:name, :description, :requester_name, :content => {})
      end

      def rbac_scope(relation)
        access_obj = RBAC::Access.new('requests', 'read').process
        raise Exceptions::NotAuthorizedError, "Not Authorized to list requests" unless access_obj.accessible?

        # return error for using wrong path
        raise Exceptions::NotAuthorizedError, "Current role cannot access #{request.path}" unless right_path?(access_obj)

        return relation if access_obj.admin?

        approver_id_list = access_obj.approver_id_list
        approver_relation = relation.where(:id => approver_id_list)
        Rails.logger.info("approver scope for requests: #{approver_id_list}")

        owner_id_list = access_obj.owner_id_list
        owner_relation = relation.where(:id => owner_id_list)
        Rails.logger.info("Owner scope for requests: #{owner_id_list}")

        # double roles for requests
        if approver_relation.any? && owner_relation.any?
          return request.path.end_with?("/approver/requests") ? approver_relation : owner_relation
        end

        # For other resources
        return approver_relation if approver_relation.any?

        owner_relation
      end

      def right_path?(access_obj)
        (access_obj.approver? && request.path.end_with?("/approver/requests")) ||
          (access_obj.owner? && request.path.end_with?("/requester/requests")) ||
          (access_obj.admin? && !request.path.end_with?("/approver/requests", "/requester/requests"))
      end
    end
  end
end
