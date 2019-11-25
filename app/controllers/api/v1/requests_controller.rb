module Api
  module V1
    class RequestsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

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
        json_response(req)
      end

      def index
        collection(index_scope(Request.all))
      end

      def index_scope(relation)
        super(relation.where(:parent_id => nil))
      end

      private

      def rbac_scope(relation)
        ids =
          case Insights::API::Common::Request.current.headers[Insights::API::Common::Request::PERSONA_KEY]
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
