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
        access_obj = RBAC::Access.new('stages', 'read').process
        return relation if access_obj.admin?

        raise Exceptions::NotAuthorizedError, "Not Authorized to list stages" unless access_obj.owner? || access_obj.accessible?

        stage_ids = access_obj.owner_id_list
        Rails.logger.info("Owner scope for stages: #{stage_ids}")

        relation.where(:id => stage_ids)
      end
    end
  end
end
