module Api
  module V1x2
    class WorkflowsController < Api::V1x0::WorkflowsController
      def show
        authorize Workflow.find(params.require(:id))

        json_response(WorkflowGetService.new(params.require(:id)).get)
      end
    end
  end
end
