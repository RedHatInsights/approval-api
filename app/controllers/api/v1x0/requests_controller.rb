module Api
  module V1x0
    class RequestsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin
      include Api::V1x0::Mixins::RBACMixin

      PERSONA_ADMIN     = 'approval/admin'.freeze
      PERSONA_APPROVER  = 'approval/approver'.freeze
      PERSONA_REQUESTER = 'approval/requester'.freeze

      before_action :read_access_check, :only => %i[show]
      before_action :create_access_check, :only => %i[create]

      def create
        req = RequestCreateService.new.create(params_for_create)
        json_response(req, :created)
      end

      def show
        req = Request.find(params.require(:id))
        request.path.end_with?("/content") ? json_response(req.content) : json_response(req)
      end

      def index
        collection(index_scope(requests_prefilter))
      end

      private

      def requests_prefilter
        return nil unless params[:request_id]

        resource_check('read', params[:request_id], Request) # NotAuthorizedError if current user cannot access parent request
        Request.find(params[:request_id]).children
      end

      def rbac_scope(relation)
        ids = nil
        case Insights::API::Common::Request.current.headers[Insights::API::Common::Request::PERSONA_KEY]
        when PERSONA_ADMIN
          raise Exceptions::NotAuthorizedError, "No permission to access the complete list of requests" unless admin?

          relation = Request.where(:parent_id => nil) unless relation
        when PERSONA_APPROVER
          raise Exceptions::NotAuthorizedError, "No permission to access requests assigned to approvers" unless approver?

          relation = Request.all unless relation
          ids = approver_id_list(relation.model.table_name)
        when PERSONA_REQUESTER, nil
          relation = Request.where(:parent_id => nil) unless relation

          ids = owner_id_list(relation.model.table_name)
        else
          raise Exceptions::NotAuthorizedError, "Unknown persona"
        end

        # for admin
        return relation unless ids

        relation.where(:id => ids)
      end
    end
  end
end
