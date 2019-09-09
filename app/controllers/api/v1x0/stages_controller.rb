module Api
  module V1x0
    class StagesController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]

      def show
        stage = Stage.find(params.require(:id))
        json_response(stage)
      end

      def index
        req = Request.find(params.require(:request_id))

        RBAC::Access.enabled? ? collection(rbac_scope(req.stages)) : collection(req.stages)
      end

      private

      def rbac_scope(relation)
        access = RBAC::ApprovalAccess.new(relation.model.table_name, 'read').process

        return relation if access.admin?

        # Only owner can reach here
        stage_ids = access.owner_id_list(relation.model.table_name)
        raise Exceptions::NotAuthorizedError, "Not Authorized for #{relation.model.table_name}" if stage_ids.empty?

        Rails.logger.info("Owner scope for stages: #{stage_ids}")

        relation.where(:id => stage_ids)
      end
    end
  end
end
