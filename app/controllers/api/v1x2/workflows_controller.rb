module Api
  module V1x2
    class WorkflowsController < Api::V1x0::WorkflowsController
      def show
        raise Exceptions::NotAuthorizedError, "Not Authorized for workflows" if Insights::API::Common::RBAC::Access.enabled? && !admin?

        json_response(WorkflowGetService.new(params.require(:id)).get)
      end
    end
  end
end
