module Api
  module V1x0
    class RequestsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      PERSONA_HEADER    = 'x-rh-persona'.freeze
      PERSONA_ADMIN     = 'approval/admin'.freeze
      PERSONA_APPROVER  = 'approval/approver'.freeze
      PERSONA_REQUESTER = 'approval/requester'.freeze

      before_action :read_access_check, :only => %i[show]
      before_action :create_access_check, :only => %i[create]

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
        ids =
          case ManageIQ::API::Common::Request.current.headers[PERSONA_HEADER]
          when PERSONA_ADMIN
            raise Exceptions::NotAuthorizedError, "No permission to access the complete list of requests" unless admin?
          when PERSONA_APPROVER
            raise Exceptions::NotAuthorizedError, "No permission to access requests assigned to approvers" unless approver?
            approver_id_list(relation.model.table_name)
          when PERSONA_REQUESTER, nil
            owner_id_list(relation.model.table_name)
          else
            raise Exceptions::NotAuthorizedError, "Unknown persona"
          end

        # for admin
        return relation unless ids

        Rails.logger.info("Accessible #{relation.model.table_name} ids: #{ids}")

        relation.where(:id => ids)
      end
    end
  end
end
