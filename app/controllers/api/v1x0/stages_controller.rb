module Api
  module V1x0
    class StagesController < ApplicationController
      include Mixins::IndexMixin

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
        access_obj = rbac_read_access(relation)
        return relation if access_obj.admin?

        # Only owner can reach here
        stage_ids = access_obj.owner_id_list
        Rails.logger.info("Owner scope for stages: #{stage_ids}")

        relation.where(:id => stage_ids)
      end
    end
  end
end
